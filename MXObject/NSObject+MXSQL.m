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

@dynamic index;

static const char *indexKey = "index";

- (int64_t)index
{
    return [objc_getAssociatedObject(self, indexKey) longLongValue];
}

- (void)setIndex:(int64_t)index
{
    objc_setAssociatedObject(self, indexKey, [NSNumber numberWithLongLong:index], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setvalueWithFields:(NSArray *)fields
{
    for (MXField *af in fields) {
        @try {
            NSString *type = [[self class] typeOfField:af.name];
            if ([type isEqualToString:MXTDate]) {
                af.value = [NSDate dateWithTimeIntervalSince1970:[af.value doubleValue]];
            }
            [self setValue:af.value forKey:af.name];
        }
        @catch (NSException *exception) {
        }
    }
}

#pragma mark === fields ===

+ (NSString *)typeOfField:(NSString *)fieldName
{
    NSString *type = [MXField typeOfField:fieldName class:self];
    return type;
}

#pragma mark === ignore fields ===

+ (NSArray *)ignoreFields
{
    return nil;
}

#pragma mark === key field ===

+ (NSString *)keyField
{
    return nil;
}

#pragma mark === MXTable ===

+ (MXTable *)table
{
    return [MXTable tableForClass:self];
}

- (MXTable *)table
{
    return [MXTable tableForObject:self];
}

#pragma mark === save ===

- (int64_t)save
{
    return [self saveWithoutFields:nil];
}

+ (void)save:(NSArray *)objects completion:(void (^)())completion
{
    [self save:objects withoutFields:nil completion:completion];
}

- (int64_t)saveWithoutFields:(NSArray *)fields
{
    MXTable *table = [self table];
    for (NSString *fieldName in fields) {
        for (MXField *field in table.fields) {
            if ([fieldName isEqualToString:field.name]) {
                [table.fields removeObject:field];
                break;
            }
        }
    }
    int64_t index = [[MXSQL sharedMXSQL] save:table];
    self.index = index;
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
    if (self.index <= 0) return NO;
    return [self freshWithField:MXSQL_INDEX];
    
    return YES;
}

- (BOOL)freshWithField:(NSString *)fieldName
{
    id value;
    @try {
        value = [self valueForKey:fieldName];
    }
    @catch (NSException *exception) {
    }
    if (!value) return NO;
    
    NSString *string = [MXCondition conditionStringWithConditions:@[[MXCondition whereKey:fieldName equalTo:value]]];
    NSArray *array = [[MXSQL sharedMXSQL] fresh:[self table] condition:string];
    if (!array.count) return NO;
    NSArray *afields = array[0];
    [self setvalueWithFields:afields];
    
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
    NSArray *array = [[MXSQL sharedMXSQL] query:[self table] field:fieldName condition:condition];
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
            [object setvalueWithFields:afields];
        }
        [objects addObject:object];
    }
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
    MXField *keyField = [self table].keyField;
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

@end