//
//  NSObject+MXTable.m
//  Pods
//
//  Created by eric on 16/8/6.
//
//

#import "NSObject+MXTable.h"
#import "MXSqliteObjCache.h"
#import <objc/runtime.h>

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

BOOL mxsql_isSqliteProtocal(Class cls)
{
    return [cls conformsToProtocol:objc_getProtocol("MXSqliteProtocal")];
}

@implementation NSObject (MXTable)

- (int64_t)mxsql_id
{
    id obj = objc_getAssociatedObject(self, _cmd);
    return [obj longLongValue];
}

- (void)setMxsql_id:(long long)mxsql_id
{
    objc_setAssociatedObject(self, @selector(mxsql_id), @(mxsql_id), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//解析类型
+ (NSString *)mxsql_getPropertyType:(objc_property_t)property
{
    if (!property) return nil;
    const char *pType = property_getAttributes(property);
    NSString *propertyType = [NSString stringWithUTF8String:pType];
    NSArray *coms = [propertyType componentsSeparatedByString:@","];
    
    //如果是readonlyo类型的，忽略；
    if (coms.count >= 2) {
        NSString *rtype = coms[1];
        if ([rtype isEqualToString:@"R"]) return nil;
    }
    
    propertyType = [coms objectAtIndex:0];
    if ([propertyType isEqualToString:@"T@\"NSString\""]) return MXTString;
    if ([propertyType isEqualToString:@"T@\"NSDate\""]) return MXTDate;
    if ([propertyType isEqualToString:@"T@\"NSData\""]) return MXTData;
    if ([propertyType isEqualToString:@"T@\"NSNumber\""]) return MXTNumber;
    if ([propertyType isEqualToString:@"Ti"]) return MXTInt;
    if ([propertyType isEqualToString:@"Tl"]) return MXTInt;
    if ([propertyType isEqualToString:@"Tq"]) return MXTLong;
    if ([propertyType isEqualToString:@"Tf"]) return MXTFloat;
    if ([propertyType isEqualToString:@"Td"]) return MXTDouble;
    if ([propertyType isEqualToString:@"Tc"]) return MXTBOOL;
    if ([propertyType isEqualToString:@"TB"]) return MXTBOOL;
    return nil;
}

//所有字段
+ (NSMutableArray *)mxsql_fields
{
    if (!mxsql_isSqliteProtocal(self)) return nil;
    NSArray *cache = [self fieldsCache];
    if (cache) return cache;
    
    NSMutableArray *fields = [NSMutableArray new];
    
    if (mxsql_isSqliteProtocal([self superclass])) {
        NSArray *superFields = [[self superclass] mxsql_fields];
        [fields addObjectsFromArray:superFields];
    }
    
    u_int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    
    for (int i = 0; i < count; i++) {
        MXField *field = [MXField new];
        objc_property_t property = properties[i];
        NSString *type = [self mxsql_getPropertyType:property];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        if (type) {
            field.type = type;
            field.name = name;
            [fields addObject:field];
        }
    }
    free(properties);
    [self cacheFields:fields];
    return fields;
}

+ (MXField *)mxsql_fieldWithName:(NSString *)fname
{
    NSArray *fields = [self mxsql_fields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:fname]) {
            return field;
        }
    }
    return nil;
}

+ (NSString *)mxsql_typeForField:(NSString *)name
{
    NSArray *fields = [self mxsql_fields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:name]) {
            return field.type;
        }
    }
    return nil;
}

+ (NSString *)mxsql_tableName
{
    return NSStringFromClass(self);
}

+ (MXField *)getPkField
{
    NSString *pk;
    if ([self instancesRespondToSelector:@selector(pkField)]) {
        pk = [self forwardingTargetForSelector:@selector(pkField)];
    }
    if ([pk isKindOfClass:[NSString class]] && [pk isEqualToString:@""]) {
        MXField *field = [self mxsql_fieldWithName:pk];
        if (!field) return field;
    }
    MXField *field = [MXField defaultPkField];
    [[self mxsql_fields] addObject:field];
    return field;
}

+ (MXTable *)mxsql_table
{
    if (!mxsql_isSqliteProtocal(self)) return nil;

    MXTable *table = [self tableCache];
    if (table) return table;
    
    table = [MXTable new];
    table.name = [self mxsql_tableName];
    table.fields = [self mxsql_fields];
    table.pkField = [self getPkField];
    [self cacheTable:table];
    
    return table;
}

- (MXRecord *)mxsql_record
{
    if (!mxsql_isSqliteProtocal(self)) return nil;
    
    MXRecord *record = objc_getAssociatedObject(self, _cmd);
    if (!record) {
        record = [MXRecord new];
        record.table = [[self class] mxsql_table];
        
        MXField *pk = [[self class] mxsql_table].pkField;
        MXFieldValue *pkv = [MXFieldValue instanceWithField:pk];
        pkv.value = [self valueForKey:pk.name];
        record.pkFieldValue = pkv;
        
        NSMutableArray *fields = [NSMutableArray new];
        for (MXField *field in [[self class] mxsql_fields]) {
            if ([field.name isEqualToString:pkv.name]) {
                [fields addObject:pkv];
                continue;
            }
            MXFieldValue *fv = [MXFieldValue instanceWithField:field];
            id value = [self valueForKey:field.name];
            fv.value = fv.value;
            [fields addObject:fv];
        }
        record.fieldValues = fields;
        
        objc_setAssociatedObject(self, _cmd, record, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return record;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mx_sqlite_hook_class_swizzleMethodAndStore(self, @selector(init), @selector(mxsql_init));
        mx_sqlite_hook_class_swizzleMethodAndStore(self, NSSelectorFromString(@"dealloc"), @selector(mxsql_dealloc));
    });
}

- (instancetype)mxsql_init
{
    id obj = [self mxsql_init];
    if (!mxsql_isSqliteProtocal([self class])) return obj;

    for (MXField *field in [[self class] mxsql_table].fields) {
        if ([field.name isEqualToString:@"mxsql_id"]) continue;
        [self addObserver:self forKeyPath:field.name options:NSKeyValueObservingOptionNew context:nil];
    }
    return obj;
}

- (void)mxsql_dealloc
{
    if (!mxsql_isSqliteProtocal([self class])) return;
    for (MXField *field in [[self class] mxsql_table].fields) {
        if ([field.name isEqualToString:@"mxsql_id"]) continue;
        [self removeObserver:self forKeyPath:field.name];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self) {
        for (MXFieldValue *fv in self.mxsql_record.fieldValues) {
            if ([fv.name isEqualToString:keyPath]) {
                fv.value = [self valueForKey:keyPath];
            }
        }
    }
}

@end

@implementation NSObject (MXSqlite)

- (BOOL)mxsql_save
{
    return [[MXSqlite objInstance] save:self.mxsql_record];
}

@end

@implementation NSObject (MXSqliteQuery)

+ (NSArray *)query:(MXSqliteQueryBlock)block
{
    
}

+ (void)query:(MXSqliteQueryBlock)block completion:(MXSqliteArrayBlock)completion
{
    MXSqliteQuery *query = [MXSqliteQuery new];
    if (block) block(query);
    //    NSArray *array = [[MXSqlite objInstance] query:[self table] include:fnames condition:condition];
    
}

+ (NSArray *)queryFields:(NSArray *)fields condition:(NSString *)condition
{
    NSArray *array = [[MXSqlite objInstance] query:[self mxsql_table] fields:fields condition:condition];
    NSMutableArray *objects = [NSMutableArray new];
    for (int i = 0; i < array.count; i++) {
        NSArray *afields = array[i];
        id object = [self new];
        [object setValueWithFields:afields];
        [objects addObject:object];
    }
    return objects;
}

- (void)setValueWithFields:(NSArray *)fields
{
    for (MXFieldValue *af in fields) {
        if ([af.value isKindOfClass:[NSNull class]]) continue;
        NSString *type = [[self class] mxsql_typeForField:af.name];
        if ([type isEqualToString:MXTDate]) {
            NSTimeInterval time = [af.value doubleValue];
            af.value = [NSDate dateWithTimeIntervalSince1970:time];
        }
        @try {
            [self setValue:af.value forKey:af.name];
        }
        @catch (NSException *exception) {
        }
    }
}

@end