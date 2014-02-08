//
//  NSObject+MXSQL.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "NSObject+MXSQL.h"
#import <objc/runtime.h>

@implementation NSObject (MXSQL)

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
        NSArray *array = [[MXSQL sharedMXSQL] query:[self table] field:fieldName condition:condition];
        NSMutableArray *objects = [NSMutableArray new];
        for (int i = 0; i < array.count; i++) {
            NSArray *afields = array[i];
            id object = !fieldName ? [self new] : nil;
            for (MXField *af in afields) {
                if (fieldName) {
                    object = af.value;
                }
                else {
                    @try {
                        [object setValue:af.value forKey:af.name];
                    }
                    @catch (NSException *exception) {
                    }
                }
            }
            [objects addObject:object];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(objects);
        });
    });
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