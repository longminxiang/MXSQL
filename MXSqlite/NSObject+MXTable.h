//
//  NSObject+MXTable.h
//  Pods
//
//  Created by eric on 16/8/6.
//
//

#import <Foundation/Foundation.h>
#import "MXTable.h"

@protocol MXSqliteProtocal <NSObject>

@optional

- (NSString *)pkField;

@end

@interface NSObject (MXTable)<MXSqliteProtocal>

@property (nonatomic, assign) int64_t mxsql_id;

+ (NSArray *)mxsql_fields;
- (NSArray *)mxsql_fields;

+ (MXField *)mxsql_fieldWithName:(NSString *)fname;
- (MXField *)mxsql_fieldWithName:(NSString *)fname;

+ (MXTable *)mxsql_table;
- (MXTable *)mxsql_table;

@end
