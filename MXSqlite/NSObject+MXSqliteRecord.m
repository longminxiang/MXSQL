//
//  NSObject+MXSqliteRecord.m
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import "NSObject+MXSqliteRecord.h"
#import <objc/runtime.h>

@interface MXSqliteRecordCache : NSObject

@property (nonatomic, readonly) NSMutableDictionary *tablesCache;

@end

@implementation MXSqliteRecordCache
@synthesize tablesCache = _tablesCache;

+ (instancetype)instance
{
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self class] new];
    });
    return object;
}

- (NSMutableDictionary *)tablesCache
{
    if (!_tablesCache) {
        _tablesCache = [NSMutableDictionary new];
    }
    return _tablesCache;
}

- (NSString *)cacheKeyForClass:(Class)cls
{
    if (!cls) return nil;
    NSString *cacheKey = [NSString stringWithFormat:@"MXSqlFieldCache_%@", [cls description]];
    return cacheKey;
}

- (void)cacheTable:(MXSqliteRecord *)table forClass:(Class)cls
{
    NSString *key = [self cacheKeyForClass:cls];
    if (table && key) {
        self.tablesCache[key] = table;
    }
}

- (MXSqliteRecord *)tableCacheWithClass:(Class)cls
{
    NSString *key = [self cacheKeyForClass:cls];
    MXSqliteRecord *table = self.tablesCache[key];
    return table;
}

@end

@implementation NSObject (MXSqliteRecordHelper)

+ (NSString *)mxsql_tableName
{
    return NSStringFromClass(self);
}

+ (BOOL)mxsql_isSqliteProtocal
{
    return [self conformsToProtocol:objc_getProtocol("MXSqliteProtocal")];
}

+ (NSMutableDictionary *)mxsql_fields
{
    Class cls = self;
    NSMutableDictionary *fields = [NSMutableDictionary new];
    if ([[cls superclass] mxsql_isSqliteProtocal]) {
        NSMutableDictionary *superFields = [[cls superclass] mxsql_fields];
        [fields addEntriesFromDictionary:superFields];
    }
    
    u_int count;
    objc_property_t *pts = class_copyPropertyList(cls, &count);
    
    for (int i = 0; i < count; i++) {
        objc_property_t pt = pts[i];
        NSString *att = [NSString stringWithUTF8String:property_getAttributes(pt)];
        NSArray *coms = [att componentsSeparatedByString:@","];
        
        //如果是readonlyo类型的，忽略；
        if (coms.count >= 2 && [ coms[1] isEqualToString:@"R"]) continue;
        
        NSString *ptt = [coms objectAtIndex:0];
        MXSqliteFieldType type = MXSqliteNullField;
        
        if ([ptt isEqualToString:@"T@\"NSString\""]) type = MXSqliteStringField;
        else if ([ptt isEqualToString:@"T@\"NSDate\""]) type = MXSqliteDateField;
        else if ([ptt isEqualToString:@"T@\"NSData\""]) type = MXSqliteDataField;
        else if ([ptt isEqualToString:@"Ti"]) type = MXSqliteIntegerField;
        else if ([ptt isEqualToString:@"Tl"]) type = MXSqliteIntegerField;
        else if ([ptt isEqualToString:@"Tq"]) type = MXSqliteIntegerField;
        else if ([ptt isEqualToString:@"Tf"]) type = MXSqliteFloatField;
        else if ([ptt isEqualToString:@"Td"]) type = MXSqliteFloatField;
        else if ([ptt isEqualToString:@"Tc"]) type = MXSqliteBoolField;
        else if ([ptt isEqualToString:@"TB"]) type = MXSqliteBoolField;
        
        if (type == MXSqliteNullField) continue;
        
        MXSqliteField *field = [MXSqliteField new];
        field.name = [NSString stringWithUTF8String:property_getName(pt)];
        field.type = type;
        fields[field.name] = field;
    }
    free(pts);
    return fields;
}

@end

@implementation NSObject (MXSqliteRecordId)

- (int64_t)mxsql_id
{
    id obj = objc_getAssociatedObject(self, _cmd);
    return [obj longLongValue];
}

- (void)setMxsql_id:(long long)mxsql_id
{
    objc_setAssociatedObject(self, @selector(mxsql_id), @(mxsql_id), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSObject (MXSqliteRecord)

+ (instancetype)mxsql_instanceWithRecord:(MXSqliteRecord *)record
{
    if (![self mxsql_isSqliteProtocal]) return nil;
    NSObject *obj = [self new];
    NSDictionary *fields = obj.mxsql_record.fields;
    [fields enumerateKeysAndObjectsUsingBlock:^(NSString *key, MXSqliteField *field, BOOL * _Nonnull stop) {
        MXSqliteField *valField = record.fields[key];
        id val = valField.value;
        if (val && ![val isKindOfClass:[NSNull class]]) {
            if (field.type == MXSqliteDateField) {
                NSTimeInterval time = [val doubleValue];
                valField.value = [NSDate dateWithTimeIntervalSince1970:time];
            }
            @try {
                [obj setValue:val forKey:field.name];
            }
            @catch (NSException *exception) {
            }
        }
    }];
    return obj;
}

- (MXSqliteRecord *)mxsql_record
{
    MXSqliteRecord *obj = objc_getAssociatedObject(self, _cmd);
    if (!obj) {
        Class cls = [self class];
        MXSqliteRecord *record = [[MXSqliteRecordCache instance] tableCacheWithClass:cls];
        if (!record) {
            record = [MXSqliteRecord new];
            record.name = [cls mxsql_tableName];
            record.fields = [cls mxsql_fields];
            
            NSString *pk;
            if ([cls instancesRespondToSelector:@selector(pkField)]) {
                pk = [cls forwardingTargetForSelector:@selector(pkField)];
            }
            if ([pk isKindOfClass:[NSString class]] && [pk isEqualToString:@""]) {
                MXSqliteField *field = record.fields[pk];
                record.pkField = field;
            }
            if (!record.pkField) {
                record.pkField = [MXSqliteField defaultPkField];
                record.fields[record.pkField.name] = record.pkField;
            }
            [[MXSqliteRecordCache instance] cacheTable:record forClass:cls];
        }
        obj = [record clone];
        objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return obj;
}

- (void)mxsql_save
{
    [self.mxsql_record.fields enumerateKeysAndObjectsUsingBlock:^(NSString *key, MXSqliteField *field, BOOL * _Nonnull stop) {
        @try {
            id value = [self valueForKey:key];
            field.value = value;
        } @catch (NSException *exception) {}
    }];
    [[MXSqlite objInstance] save:self.mxsql_record];
}

@end

@interface MXSqliteQuery (Result)

@property (nonatomic, readonly) MXSqliteResult *result;

@end

@implementation MXSqliteQuery (Result)

- (MXSqliteResult *)result
{
    id obj = objc_getAssociatedObject(self, _cmd);
    if (!obj) {
        obj = [MXSqliteResult new];
        objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return obj;
}

@end

@interface MXSqliteResult ()

@property (nonatomic, assign) Class targetClass;
@property (nonatomic, weak) MXSqliteQuery *query;

@end

@implementation MXSqliteResult

- (NSArray *)objs
{
    NSArray *records = [[MXSqlite objInstance] query:[self.targetClass mxsql_tableName] fields:nil condition:self.query.queryString];
    NSMutableArray *objs = [NSMutableArray new];
    for (int i = 0; i < records.count; i++) {
        MXSqliteRecord *record = records[i];
        id obj = [self.targetClass mxsql_instanceWithRecord:record];
        [objs addObject:obj];
    }
    return objs;
}

- (void)asyncObjs:(void (^)(NSArray *objs))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *objs = self.objs;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) block(objs);
        });
    });
}

- (NSInteger)count
{
    NSInteger count = [[MXSqlite objInstance] count:[self.targetClass mxsql_tableName] condition:self.query.queryString];
    return count;

}

- (BOOL)deleted
{
    BOOL deleted = [[MXSqlite objInstance] deleted:[self.targetClass mxsql_tableName] condition:self.query.queryString];
    return deleted;
}

- (void)dealloc
{
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
}

@end

@implementation NSObject (MXSqliteQuery)

+ (MXSqliteResult *)query:(MXSqliteQueryBlock)block
{
    MXSqliteQuery *query = [MXSqliteQuery new];
    query.result.targetClass = self;
    if (block) block(query);
    return query.result;
}

@end