//
//  MXSqliteQuery.h
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MXSqliteQueryOperator)
{
    MXSqliteQueryOperatorEqual = 1,
    MXSqliteQueryOperatorLess,
    MXSqliteQueryOperatorGreater,
    MXSqliteQueryOperatorNotEqual,
    MXSqliteQueryOperatorLessOrEqual,
    MXSqliteQueryOperatorGreaterOrEqual,
};

typedef NS_ENUM(NSInteger, MXSqliteQuerySort)
{
    MXSqliteQuerySortAscending = 1,
    MXSqliteQuerySortDescending = 2,
};

@interface MXSqliteQuery : NSObject

typedef MXSqliteQuery* (^MXSqliteQueryOperatorBlock)(NSString *key, MXSqliteQueryOperator op, id val);

typedef MXSqliteQuery* (^MXSqliteQuerySortBlock)(NSString *key, MXSqliteQuerySort sort);

typedef MXSqliteQuery* (^MXSqliteQueryLimitBlock)(NSInteger begin,  NSInteger count);

@property (nonatomic, readonly) MXSqliteQueryOperatorBlock operate;

@property (nonatomic, readonly) MXSqliteQueryOperatorBlock orOperate;

@property (nonatomic, readonly) MXSqliteQuerySortBlock sort;

@property (nonatomic, readonly) MXSqliteQueryLimitBlock limit;

- (NSString *)queryString;

@end