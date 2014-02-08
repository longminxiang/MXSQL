//
//  NSObject+MXSQL.h
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXSQL.h"
#import "MXCondition.h"

@interface NSObject (MXSQL)

+ (NSString *)keyField;
+ (NSArray *)ignoreFields;

- (int64_t)save;
- (int64_t)saveWithoutFields:(NSArray *)fields;

+ (void)save:(NSArray *)objects completion:(void (^)())completion;
+ (void)save:(NSArray *)objects withoutFields:(NSArray *)fields completion:(void (^)())completion;

+ (void)queryAll:(void (^)(NSArray *objects))completion;

+ (void)query:(void (^)(NSArray *objects))completion conditions:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (void)query:(void (^)(NSArray *objects))completion conditionString:(NSString *)conditionString;

+ (void)query:(void (^)(NSArray *objects))completion field:(NSString *)fieldName conditions:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (void)query:(void (^)(NSArray *objects))completion field:(NSString *)fieldName conditionString:(NSString *)conditionString;

+ (int)count;
+ (int)countWithCondition:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (int)countWithConditionString:(NSString *)conditionString;

- (BOOL)delete;
+ (BOOL)deleteWithCondition:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (BOOL)deleteWithConditionString:(NSString *)conditionString;

@end
