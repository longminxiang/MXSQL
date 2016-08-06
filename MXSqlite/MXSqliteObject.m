//
//  MXSqliteObject.m
//  MXSQLDemo
//
//  Created by eric on 15/4/24.
//  Copyright (c) 2015年 longminxiang. All rights reserved.
//

#import "MXSqliteObject.h"
#import "MXSqliteObjCache.h"
#import <objc/runtime.h>

@implementation MXSqliteObject

#pragma mark
#pragma mark === fields ===

//解析类型
+ (NSString *)getPropertyType:(objc_property_t)property
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
+ (NSArray *)fields
{
    NSArray *cache = [self fieldsCache];
    if (cache) return cache;
    return [self getFields];
}

+ (NSArray *)getFields
{
    NSMutableArray *fields = [NSMutableArray new];
    
    if ([[self superclass] isSubclassOfClass:[MXSqliteObject class]]) {
        NSArray *superFields = [[self superclass] fields];
        [fields addObjectsFromArray:superFields];
    }
    
    u_int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    
    for (int i = 0; i < count; i++) {
        MXField *field = [MXField new];
        objc_property_t property = properties[i];
        NSString *type = [self getPropertyType:property];
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


- (NSArray *)fields
{
    NSArray *fields = [[self class] fields];
    for (MXField *field in [[self class] fields]) {
        id value = [self valueForKey:field.name];
        field.value = value;
    }
    return fields;
}

+ (MXField *)fieldWithName:(NSString *)fname
{
    NSArray *fields = [self fields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:fname]) {
            return field;
        }
    }
    return nil;
}

- (MXField *)fieldWithName:(NSString *)fname
{
    NSArray *fields = [self fields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:fname]) {
            return field;
        }
    }
    return nil;
}

- (NSString *)typeWithFieldName:(NSString *)name
{
    NSArray *fields = [self fields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:name]) {
            return field.type;
        }
    }
    return nil;
}

+ (NSString *)keyField
{
    return nil;
}

#pragma mark
#pragma mark === table ===

+ (NSString *)clsName
{
    const char *n = class_getName(self);
    NSString *name = [NSString stringWithCString:n encoding:NSASCIIStringEncoding];
    return name;
}

+ (MXTable *)table
{
    MXTable *table = [self tableCache];
    if (table) return table;
    
    table = [MXTable new];
    table.name = [self clsName];
    table.keyField = [self fieldWithName:[self keyField]];
    table.fields = [self fields];
    [self cacheTable:table];
    
    return table;
}

- (MXTable *)table
{
    MXTable *table = [[self class] table];
    table.fields = [self fields];
    table.keyField = [self fieldWithName:[[self class] keyField]];
    return table;
}

@end

@implementation MXSqliteObject (SQLMethod)

#pragma mark
#pragma mark === save ===

- (int64_t)save
{
    return [self saveExclude:nil];
}

+ (void)save:(NSArray *)objects completion:(void (^)())completion
{
    if (!objects.count) {
        if (completion) completion();
        return;
    }
    [self save:objects exclude:nil completion:completion];
}

+ (void)save:(NSArray *)objects exclude:(NSArray *)fields completion:(void (^)())completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < objects.count; i++) {
            id object = objects[i];
            [object saveExclude:fields];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    });
}

- (int64_t)saveExclude:(NSArray *)fields
{
    MXTable *table = [self table];
    
    //如果有要忽略的field,克隆一个table实例存储
    if (fields.count) {
        table = [table cloneWithExcludeFields:fields];
    }
    
    int64_t idx = [[MXSqlite objInstance] save:table];
    self.idx = idx;
    return self.idx;
}

#pragma mark
#pragma mark === fresh ===

- (BOOL)freshWithKeyField
{
    NSString *keyField = [[self class] keyField];
    if (!keyField) return NO;
    return [self freshWithField:keyField];
}

- (BOOL)freshWithIdx
{
    if (self.idx <= 0) return NO;
    return [self freshWithField:IDX_FIELD_NAME];
}

- (BOOL)freshWithField:(NSString *)fieldName
{
    id value;
    @try {value = [self valueForKey:fieldName];}
    @catch (NSException *exception) {}
    if (!value) return NO;
    
    NSString *string = [MXCondition conditionStringWithConditions:@[[MXCondition whereKey:fieldName equalTo:value]]];
    NSArray *array = [[MXSqlite objInstance] fresh:[self table] condition:string];
    if (!array.count) return NO;
    NSArray *afields = array[0];
    [self setValueWithFields:afields];
    return YES;
}

#pragma mark
#pragma mark === query ===

#define CONDITION_STRING \
NSMutableArray *conditions = [NSMutableArray new]; \
va_list args; \
va_start(args, condition); \
while (condition) { \
[conditions addObject:condition]; \
condition = va_arg(args, id); \
} \
va_end(args); \
NSString *conditionString = [MXCondition conditionStringWithConditions:conditions]

+ (void)query:(void (^)(id object))completion keyFieldValue:(id)value
{
    if (!value || ![self keyField]) {
        completion(nil);
    }
    else {
        [self query:^(NSArray *objects) {
            if (!objects.count) {
                completion(nil);
            }
            else {
                completion(objects[0]);
            }
        } conditions:[MXCondition whereKey:[self keyField] equalTo:value], nil];
    }
}

//查询所有
+ (void)queryAll:(void (^)(NSArray *objects))completion
{
    [self query:completion conditionString:nil];
}

//条件查询
+ (void)query:(void (^)(NSArray *objects))completion conditions:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION
{
    CONDITION_STRING;
    [self query:completion conditionString:conditionString];
}

+ (void)query:(void (^)(NSArray *objects))completion conditionString:(NSString *)conditionString
{
    [self queryField:nil condition:conditionString completion:completion];
}

+ (void)query:(void (^)(NSArray *objects))completion field:(NSString *)fieldName conditions:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION
{
    CONDITION_STRING;
    [self query:completion field:fieldName conditionString:conditionString];
}

+ (void)query:(void (^)(NSArray *objects))completion field:(NSString *)fieldName conditionString:(NSString *)conditionString
{
    [self queryField:fieldName condition:conditionString completion:completion];
}

+ (void)queryField:(NSString *)fieldName condition:(NSString *)condition completion:(void (^)(NSArray *objects))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *objects = [self queryField:fieldName condition:condition];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(objects);
        });
    });
}

+ (NSArray *)queryField:(NSString *)fieldName condition:(NSString *)condition
{
    NSArray *fnames = fieldName ? @[fieldName] : nil;
    NSArray *array = [[MXSqlite objInstance] query:[self table] include:fnames condition:condition];
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < array.count; i++) {
        NSArray *afields = array[i];
        if (fieldName) {
            if (afields.count) {
                MXField *af = afields[0];
                [objects addObject:af.value];
            }
        }
        else {
            MXSqliteObject *object = [self new];
            [object setValueWithFields:afields];
            if (object) [objects addObject:object];
        }
    }
    if (!objects.count) objects = nil;
    return objects;
}


- (void)setValueWithFields:(NSArray *)fields
{
    for (MXField *af in fields) {
        if ([af.value isKindOfClass:[NSNull class]]) continue;
        NSString *type = [self typeWithFieldName:af.name];
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

#pragma mark
#pragma mark === count ===

+ (int)count
{
    return [self countWithConditionString:nil];
}

+ (int)countWithCondition:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION
{
    CONDITION_STRING;
    return [self countWithConditionString:conditionString];
}

+ (int)countWithConditionString:(NSString *)conditionString
{
    return [[MXSqlite objInstance] count:[self clsName] condition:conditionString];
}

#pragma mark
#pragma mark === delete ===

- (BOOL)delete
{
    MXField *keyField = [self table].keyField;
    if (!keyField)
        return [[self class] deleteWithCondition:[MXCondition whereKey:IDX_FIELD_NAME equalTo:@(self.idx)], nil];
    else
        return [[self class] deleteWithCondition:[MXCondition whereKey:keyField.name equalTo:keyField.value], nil];
}

+ (BOOL)deleteWithCondition:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION
{
    CONDITION_STRING;
    return [self deleteWithConditionString:conditionString];
}

+ (BOOL)deleteWithConditionString:(NSString *)conditionString
{
    return [[MXSqlite objInstance] delete:[self clsName] condition:conditionString];
}

+ (BOOL)deleteAll
{
    return [[MXSqlite objInstance] delete:[self clsName] condition:nil];
}

@end

@implementation MXSqliteQuery

- (MXSqliteConditionBlock)c
{
    return ^MXSqliteQuery *(NSString *key, MXSqliteConditionType type, id val) {
        return self;
    };
}

- (MXSqliteConditionOrderBlock)o
{
    return ^MXSqliteQuery *(MXSqliteConditionOrder order) {
        return self;
    };
}

@end

@implementation NSObject (SQLMethod)

+ (NSArray *)query:(MXSqliteQueryBlock)block
{

}

+ (void)query:(MXSqliteQueryBlock)block completion:(MXSqliteArrayBlock)completion
{
    MXSqliteQuery *query = [MXSqliteQuery new];
    if (block) block(query);
//    NSArray *array = [[MXSqlite objInstance] query:[self table] include:fnames condition:condition];

}

@end
