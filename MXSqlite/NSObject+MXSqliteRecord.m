//
//  NSObject+MXSqliteRecord.m
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import "NSObject+MXSqliteRecord.h"
#import "MXSqliteObjCache.h"
#import <objc/runtime.h>

@interface MXSqliteRecordManager : NSObject

@property (nonatomic, assign) Class recordClass;

@property (nonatomic, readonly) NSMutableDictionary *tablesCache;

@property (nonatomic, readonly) MXSqliteRecord *record;

@end

@implementation MXSqliteRecordManager
@synthesize tablesCache = _tablesCache;
@synthesize record = _record;

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
    MXTable *table = self.tablesCache[key];
    return table;
}

@end

@implementation MXSqliteRecordManager (RecordClass)

+ (instancetype)initWithRecordClass:(Class)cls
{
    if (![cls conformsToProtocol:objc_getProtocol("MXSqliteProtocal")]) return nil;
    MXSqliteRecordManager *manager = [MXSqliteRecordManager new];
    manager.recordClass = cls;
    return manager;
}

- (BOOL)isSqliteProtocal:(Class)cls
{
    return [cls conformsToProtocol:objc_getProtocol("MXSqliteProtocal")];
}

- (NSMutableDictionary *)fieldsWithClass:(Class)cls
{
    
    NSMutableDictionary *fields = [NSMutableDictionary new];
    if ([self isSqliteProtocal:[cls superclass]]) {
        NSMutableDictionary *superFields = [self fieldsWithClass:[cls superclass]];
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

- (MXSqliteRecord *)table
{
    MXSqliteRecord *table = [[MXSqliteRecordManager instance] tableCacheWithClass:self.recordClass];
    if (table) return table;
    
    Class cls = self.recordClass;

    table = [MXSqliteRecord new];
    table.name = NSStringFromClass(cls);
    table.fields = [self fieldsWithClass:cls];
    
    NSString *pk;
    if ([cls instancesRespondToSelector:@selector(pkField)]) {
        pk = [cls forwardingTargetForSelector:@selector(pkField)];
    }
    if ([pk isKindOfClass:[NSString class]] && [pk isEqualToString:@""]) {
        MXSqliteField *field = table.fields[pk];
        table.pkField = field;
    }
    if (!table.pkField) {
        table.pkField = [MXSqliteField defaultPkField];
        table.fields[table.pkField.name] = table.pkField;
    }
    [[MXSqliteRecordManager instance] cacheTable:table forClass:cls];
    return table;
}

- (MXSqliteRecord *)record
{
    if (!_record) {
        _record = [[self table] clone];
        [_record.fields enumerateKeysAndObjectsUsingBlock:^(NSString *key, MXSqliteField *field, BOOL * _Nonnull stop) {
            id value = [self valueForKey:key];
            field.value = value;
        }];
    }
    return _record;
}

- (void)addFieldValueObservers
{
    NSDictionary *fields = self.record.fields;
    [fields enumerateKeysAndObjectsUsingBlock:^(NSString *key, MXSqliteField *field, BOOL * _Nonnull stop) {
        if (![field isDefaultPkField]) {
            [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:nil];
        }
    }];
}

- (void)mxsql_removeFieldValueObservers
{
    if (![self mxsql_isSqliteProtocal]) return;
    NSDictionary *fields = [[self class] mxsql_table].fields;
    [fields enumerateKeysAndObjectsUsingBlock:^(NSString *key, MXSqliteField *field, BOOL * _Nonnull stop) {
        if (![field isDefaultPkField]) {
            [self removeObserver:self forKeyPath:key];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self) {
        MXSqliteField *field = [self mxsql_record].fields[keyPath];
        field.value = [self valueForKey:keyPath];
    }
}



@end

@implementation NSObject (MXSqliteDefaultPkField)

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

@end

@implementation NSObject (MXSqliteRecordHook)

void mx_sqlite_hook_class_swizzleMethodAndStore(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mx_sqlite_hook_class_swizzleMethodAndStore(self, NSSelectorFromString(@"dealloc"), @selector(mxsql_dealloc));
    });
}

- (void)mxsql_dealloc
{
    [self mxsql_removeFieldValueObservers];
    [self mxsql_dealloc];
}

@end


