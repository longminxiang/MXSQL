//
//  MXSqliteObject.h
//  MXSQLDemo
//
//  Created by eric on 15/4/24.
//  Copyright (c) 2015年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXSqlite.h"
#import "MXCondition.h"

@interface MXSqliteObject : NSObject

@property (nonatomic, assign) int64_t idx;

// override this method to set key field
+ (NSString *)keyField;

+ (NSArray *)fields;
- (NSArray *)fields;

+ (MXField *)fieldWithName:(NSString *)fname;
- (MXField *)fieldWithName:(NSString *)fname;

+ (MXTable *)table;
- (MXTable *)table;

@end

@interface MXSqliteObject (SQLMethod)

//保存
- (int64_t)save;
- (int64_t)saveExclude:(NSArray *)fields;

+ (void)save:(NSArray *)objects completion:(void (^)())completion;
+ (void)save:(NSArray *)objects exclude:(NSArray *)fields completion:(void (^)())completion;

//刷新
- (BOOL)freshWithKeyField;
- (BOOL)freshWithIdx;
- (BOOL)freshWithField:(NSString *)fieldName;

//查询所有
+ (void)queryAll:(void (^)(NSArray *objects))completion;

//条件查询
+ (void)query:(void (^)(NSArray *objects))completion conditions:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (void)query:(void (^)(NSArray *objects))completion conditionString:(NSString *)conditionString;

//条件查询单个字段
+ (void)query:(void (^)(NSArray *objects))completion field:(NSString *)fieldName conditions:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (void)query:(void (^)(NSArray *objects))completion field:(NSString *)fieldName conditionString:(NSString *)conditionString;

//查询数量
+ (int)count;
+ (int)countWithCondition:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (int)countWithConditionString:(NSString *)conditionString;

//删除
- (BOOL)delete;
+ (BOOL)deleteWithCondition:(MXCondition *)condition, ...NS_REQUIRES_NIL_TERMINATION;
+ (BOOL)deleteWithConditionString:(NSString *)conditionString;
+ (BOOL)deleteAll;

@end
