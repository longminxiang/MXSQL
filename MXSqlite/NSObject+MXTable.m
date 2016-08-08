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

BOOL mxsql_isSqliteProtocal(Class cls)
{
    return class_conformsToProtocol(cls, objc_getProtocol("MXSqliteProtocal"));
}

@implementation NSObject (MXTable)

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
+ (NSArray *)mxsql_fields
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
    if (!fields.count) fields = nil;
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
        if (field) return field;
    }
    return [MXField defaultPkField];
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
        
        MXField *pk = [[self class] getPkField];
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

@end

@implementation NSObject (MXSqlite)

#pragma mark
#pragma mark === save ===

- (BOOL)save
{
    return [[MXSqlite objInstance] save:self.mxsql_record];
}

+ (void)save:(NSArray *)objects completion:(void (^)())completion
{
    if (!objects.count) {
        if (completion) completion();
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < objects.count; i++) {
            id object = objects[i];
            [object save];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    });
}

@end