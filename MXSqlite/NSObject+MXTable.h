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

@protocol MXSqliteProtocal <NSObject>

@optional

- (NSString *)pkField;

@end

@interface NSObject (MXTable)

@property (nonatomic, assign) int64_t mxsql_id;

+ (MXTable *)mxsql_table;

- (MXRecord *)mxsql_record;

@end

@interface NSObject (MXSqlite)

@end
