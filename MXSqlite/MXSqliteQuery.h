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
typedef MXSqliteQuery* (^MXSqliteQuerySortBlock)(MXSqliteQuerySort sort);

@property (nonatomic, readonly) MXSqliteQueryOperatorBlock op;

@property (nonatomic, readonly) MXSqliteQuerySortBlock st;

@end