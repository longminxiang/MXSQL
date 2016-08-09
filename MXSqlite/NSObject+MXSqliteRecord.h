//
//  NSObject+MXSqliteRecord.h
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import <Foundation/Foundation.h>
#import "MXSqlite.h"
#import "MXSqliteQuery.h"

@protocol MXSqliteProtocal <NSObject>

@optional

+ (NSString *)pkField;

@end

@interface NSObject (MXSqliteRecordId)

@property (nonatomic, assign) long long mxsql_id;

@end


@interface NSObject (MXSqliteRecord)

@property (nonatomic, readonly) MXSqliteRecord *mxsql_record;

- (void)mxsql_save;

@end

@interface NSObject (MXSqliteQuery)

typedef void (^MXSqliteQueryBlock)(MXSqliteQuery *query);

typedef void (^MXSqliteArrayBlock)(NSArray *objs);

+ (NSArray *)query:(MXSqliteQueryBlock)block;

+ (void)query:(MXSqliteQueryBlock)block completion:(MXSqliteArrayBlock)completion;

@end
