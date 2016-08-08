//
//  NSObject+MXTable.h
//  Pods
//
//  Created by eric on 16/8/6.
//
//

#import <Foundation/Foundation.h>
#import "MXTable.h"
#import "MXSqlite.h"
#import "MXSqliteQuery.h"

@protocol MXSqliteProtocal <NSObject>

@optional

+ (NSString *)pkField;

@end

@interface NSObject (MXTable)

@property (nonatomic, assign) long long mxsql_id;

+ (MXTable *)mxsql_table;

- (MXRecord *)mxsql_record;

@end

@interface NSObject (MXSqlite)

- (BOOL)mxsql_save;

@end

@interface NSObject (MXSqliteQuery)

typedef void (^MXSqliteQueryBlock)(MXSqliteQuery *query);

typedef void (^MXSqliteArrayBlock)(NSArray *objs);

+ (NSArray *)query:(MXSqliteQueryBlock)block;

+ (void)query:(MXSqliteQueryBlock)block completion:(MXSqliteArrayBlock)completion;

@end
