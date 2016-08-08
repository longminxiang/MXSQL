//
//  MXSqliteQuery.h
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import <Foundation/Foundation.h>
#import "MXCondition.h"

@interface MXSqliteQuery : NSObject

typedef MXSqliteQuery* (^MXSqliteConditionBlock)(NSString *key, MXSqliteConditionType type, id val);
typedef MXSqliteQuery* (^MXSqliteConditionOrderBlock)(MXSqliteConditionOrder order);

@property (nonatomic, readonly) MXSqliteConditionBlock c;

@property (nonatomic, readonly) MXSqliteConditionOrderBlock o;

@end