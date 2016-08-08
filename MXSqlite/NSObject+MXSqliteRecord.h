//
//  NSObject+MXSqliteRecord.h
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import <Foundation/Foundation.h>
#import "MXSqliteRecord.h"

@protocol MXSqliteProtocal <NSObject>

@optional

+ (NSString *)pkField;

@end

@interface NSObject (MXSqliteDefaultPkField)

@property (nonatomic, assign) long long mxsql_id;

@end

@interface NSObject (MXSqliteRecord)

- (MXSqliteRecord *)mxsql_record;

@end
