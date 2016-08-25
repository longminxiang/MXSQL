//
//  MXSqlite.h
//  MXSQLDemo
//
//  Created by eric on 15/5/30.
//  Copyright (c) 2015年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"
#import "MXSqliteRecord.h"

@interface MXSqlite : NSObject

@property (nonatomic, copy) NSString *dbPath;

+ (instancetype)objInstance;

- (void)setDefaultDbPath;
- (void)setDbPath:(NSString *)path directory:(NSSearchPathDirectory)directory;

//保存
- (BOOL)save:(MXSqliteRecord *)record;

//查询
- (NSArray *)query:(NSString *)tableName fields:(NSArray *)fields condition:(NSString *)conditionString;

//查询数量
- (int)count:(NSString *)tableName condition:(NSString *)conditionString;

//删除
- (BOOL)deleted:(NSString *)tableName condition:(NSString *)conditionString;

@end
