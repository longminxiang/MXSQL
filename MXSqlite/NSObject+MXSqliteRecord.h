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

@interface MXSqliteResult :NSObject

@property (nonatomic, readonly) NSArray *objs;

@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, readonly) BOOL deleted;

- (void)asyncObjs:(void (^)(NSArray *objs))block;

@end

@interface NSObject (MXSqliteQuery)

typedef void (^MXSqliteQueryBlock)(MXSqliteQuery *q);

+ (MXSqliteResult *)query:(MXSqliteQueryBlock)block;

@end
