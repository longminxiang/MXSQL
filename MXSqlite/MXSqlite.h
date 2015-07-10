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
#import "MXTable.h"

@interface MXSqlite : NSObject

@property (nonatomic, copy) NSString *dbPath;

+ (instancetype)objInstance;

- (void)setDefaultDbPath;
- (void)setDbPath:(NSString *)path directory:(NSSearchPathDirectory)directory;

//保存
- (int64_t)save:(MXTable *)table;

//同步
- (NSArray *)fresh:(MXTable *)table condition:(NSString *)conditionString;

//查询
- (NSArray *)query:(MXTable *)table include:(NSArray *)fields condition:(NSString *)conditionString;

//查询数量
- (int)count:(NSString *)table condition:(NSString *)conditionString;

//删除
- (BOOL)delete:(NSString *)table condition:(NSString *)conditionString;

@end
