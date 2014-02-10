//
//  MXSQL.h
//
//  Created by longminxiang on 14-1-23.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXTable.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"

#define MXSQL_INDEX @"iindex"

@interface MXSQL : NSObject

@property (nonatomic, readonly) NSString *currentDBPath;

+ (instancetype)sharedMXSQL;

- (void)setDatabasePath:(NSString *)path directory:(NSSearchPathDirectory)directory;

- (int64_t)save:(MXTable *)table;

- (NSArray *)fresh:(MXTable *)table condition:(NSString *)conditionString;

- (NSArray *)query:(MXTable *)table field:(NSString *)field condition:(NSString *)conditionString;

- (int)count:(NSString *)table condition:(NSString *)conditionString;

- (BOOL)delete:(NSString *)table condition:(NSString *)conditionString;

@end
