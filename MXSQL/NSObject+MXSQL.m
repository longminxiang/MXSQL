//
//  NSObject+MXSQL.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "NSObject+MXSQL.h"
#import <objc/runtime.h>

@implementation NSObject (MXSQL)

#pragma mark === index ===

@dynamic iindex;

static const char *iindexKey = "iindex";

- (int64_t)iindex
{
    return [objc_getAssociatedObject(self, iindexKey) longLongValue];
}

- (void)setIindex:(int64_t)iindex
{
    objc_setAssociatedObject(self, iindexKey, [NSNumber numberWithLongLong:iindex], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setValueWithFields:(NSArray *)fields
{
    for (MXField *af in fields) {
        if ([af.value isKindOfClass:[NSNull class]]) continue;
        @try {
            [self setValue:af.value forKey:af.name];
        }
        @catch (NSException *exception) {
        }
    }
}

#pragma mark === MXTable ===

- (MXTable *)tableWithIIndex
{
    MXTable *table = [self mxTable];
    if (!table.keyField && self.iindex) {
        MXField *field = [MXField new];
        field.name = MXSQL_INDEX;
        field.type = MXTInt;
        field.value = [NSNumber numberWithLongLong:self.iindex];
        table.keyField = field;
    }
    return table;
}

#pragma mark === save ===

- (int64_t)save
{
    return [self saveWithoutFields:nil];
}

+ (void)save:(NSArray *)objects completion:(void (^)())completion
{
    if (!objects.count) {
        if (completion) completion();
        return;
    }
    [self save:objects withoutFields:nil completion:completion];
}

- (int64_t)saveWithoutFields:(NSArray *)fields
{
    MXTable *table = [self tableWithIIndex];
    
    //如果有要忽略的field,克隆一个table实例存储
    if (fields.count) {
        table = [table clone];
        NSMutableArray *array = [NSMutableArray arrayWithArray:table.fields];
        for (NSString *fieldName in fields) {
            for (MXField *field in table.fields) {
                if ([fieldName isEqualToString:field.name]) {
                    [array removeObject:field];
                    break;
                }
            }
        }
        table.fields = array;
    }
    
    int64_t index = [[MXSQL sharedMXSQL] save:table];
    self.iindex = index;
    return index;
}

+ (void)save:(NSArray *)objects withoutFields:(NSArray *)fields completion:(void (^)())completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < objects.count; i++) {
            id object = objects[i];
            [object saveWithoutFields:fields];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    });
}

#pragma mark === fresh ===

- (BOOL)freshWithKeyField
{
    NSString *keyField = [[self class] keyField];
    if (!keyField) return NO;
    return [self freshWithField:keyField];
}

- (BOOL)freshWithIndex
{
    if (self.iindex <= 0) return NO;
    return [self freshWithField:MXSQL_INDEX];
}

- (BOOL)freshWithField:(NSString *)fieldName
{
    id value;
    @try {value = [self valueForKey:fieldName];}
    @catch (NSException *exception) {}
    if (!value) return NO;
    
    NSString *string = [MXCondition conditionStringWithConditions:@[[MXCondition whereKey:fieldName equalTo:value]]];
    NSArray *array = [[MXSQL sharedMXSQL] fresh:[self tableWithIIndex] condition:string];
    if (!array.count) return NO;
    NSArray *afields = array[0];
    [self setValueWithFields:afields];
    
    return YES;
}

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
    NSArray *array = [[MXSQL sharedMXSQL] query:[self mxTable] field:fieldName condition:condition];
    NSMutableArray *objects = [NSMutableArray new];
    for (int i = 0; i < array.count; i++) {
        NSArray *afields = array[i];
        NSObject *object = !fieldName ? [self new] : nil;
        if (fieldName) {
            for (MXField *af in afields) {
                object = af.value;
            }
        }
        else {
            [object setValueWithFields:afields];
        }
        if (object) [objects addObject:object];
    }
    if (!objects.count) objects = nil;
    return objects;
}

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
    return [[MXSQL sharedMXSQL] count:[self description] condition:conditionString];
}

#pragma mark === delete ===

- (BOOL)delete
{
    MXField *keyField = [self mxTable].keyField;
    if (!keyField)
        return NO;
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
    return [[MXSQL sharedMXSQL] delete:[self description] condition:conditionString];
}

+ (BOOL)deleteAll
{
    return [[MXSQL sharedMXSQL] delete:[self description] condition:nil];
}


@end