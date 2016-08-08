//
//  MXSqlite.m
//  MXSQLDemo
//
//  Created by eric on 15/5/30.
//  Copyright (c) 2015年 longminxiang. All rights reserved.
//

#import "MXSqlite.h"

#define MXSQL_DEFAULT_DB_PATH @"MXSqlite/default.db"

@interface MXSqlite ()

//数据库表名和字段名缓存{表名:字段}
@property (nonatomic, readonly) NSMutableDictionary *dbCaches;

@property (nonatomic, strong, readonly) FMDatabaseQueue *saveQueue, *queryQueue, *freshQueue;
@property (nonatomic, strong, readonly) FMDatabaseQueue *countQueue, *deleteQueue;

@end

@implementation MXSqlite
@synthesize dbCaches = _dbCaches;

+ (instancetype)objInstance
{
    static id obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [self new];
    });
    return obj;
}

- (id)init
{
    if (self = [super init]) {
        _dbCaches = [NSMutableDictionary new];
        [self setDefaultDbPath];
    }
    return self;
}

#pragma mark
#pragma mark === setter ===

- (void)setDbPath:(NSString *)dbPath
{
    if ([_dbPath isEqualToString:dbPath]) return;
    _dbPath = [dbPath copy];
    
    [self updateDatabase];
}

- (void)setDefaultDbPath
{
    [self setDbPath:MXSQL_DEFAULT_DB_PATH directory:NSDocumentDirectory];
}

- (void)setDbPath:(NSString *)path directory:(NSSearchPathDirectory)directory
{
    NSString *dir = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES)[0];
    NSArray *pathArr = [path componentsSeparatedByString:@"/"];
    if (pathArr.count > 1) {
        NSString *rdir = [dir stringByAppendingPathComponent:[path substringToIndex:path.length - [pathArr.lastObject length] - 1]];
        [[NSFileManager defaultManager] createDirectoryAtPath:rdir withIntermediateDirectories:YES attributes:nil error:NULL];
        path = [rdir stringByAppendingPathComponent:pathArr.lastObject];
    }
    else {
        path = [dir stringByAppendingPathComponent:path];
    }
    self.dbPath = path;
}

#pragma mark
#pragma mark === dbs ===

- (void)updateDatabase
{
    _saveQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
    _queryQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
    _freshQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
    _countQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
    _deleteQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
    
    [self getDBFields];
}

//获取当前数据库表名和字段名
- (void)getDBFields
{
    [self.dbCaches removeAllObjects];
    [self.saveQueue inDatabase:^(FMDatabase *db) {
        NSArray *tables = [self getTablesNameInDB:db];
        for (NSString *tbname in tables) {
            NSArray *fields = [self getFieldNamesWithTable:tbname db:db];
            self.dbCaches[tbname] = fields;
        }
    }];
}

//获取当前数据库表名
- (NSArray *)getTablesNameInDB:(FMDatabase *)db
{
    NSMutableArray *array = [NSMutableArray new];
    FMResultSet *rs = [db getSchema];
    while ([rs next]) {
        NSString *str = [rs stringForColumn:@"tbl_name"];
        [array addObject:str];
    }
    [rs close];
    if (!array.count) array = nil;
    return array;
}

//获取表的字段名
- (NSArray *)getFieldNamesWithTable:(NSString *)table db:(FMDatabase *)db
{
    NSMutableArray *array = [NSMutableArray new];
    FMResultSet *rs = [db getTableSchema:table];
    while ([rs next]) {
        NSString *str = [rs stringForColumn:@"name"];
        [array addObject:str];
    }
    [rs close];
    if (!array.count) array = nil;
    return array;
}

#pragma mark
#pragma mark === current db ===

//创建表
- (void)createTable:(MXTable *)table db:(FMDatabase *)db
{
    if ([[self.dbCaches allKeys] containsObject:table.name]) return;
    
    NSMutableArray *fieldNames = [NSMutableArray new];
    NSArray *fields = table.fields;
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (",table.name];
    for (int i = 0; i < fields.count; i++) {
        MXField *field = fields[i];
        NSString *fstr = (i == fields.count - 1) ? @")" : @",";
        NSString *pstr = @"";
        if ([field.name isEqualToString:table.pkField.name]) {
            pstr = @" PRIMARY KEY";
            if ([field.type isEqualToString:MXTInt] || [field.type isEqualToString:MXTLong]) {
                pstr = [pstr stringByAppendingString:@" AUTOINCREMENT"];
            }
        }
        sql = [sql stringByAppendingFormat:@"'%@' %@%@%@", field.name, field.type, pstr,fstr];
        [fieldNames addObject:field.name];
    }
    if ([db executeUpdate:sql] && fieldNames.count) {
        [self.dbCaches setObject:fieldNames forKey:table.name];
    }
}

//更新表
- (void)updateTable:(MXTable *)table db:(FMDatabase *)db
{
    NSArray *oldFields = [self.dbCaches objectForKey:table.name];
    
    //判断dbCaches里是否有此表
    if (!oldFields.count) {
        [self createTable:table db:db];
        return;
    }
    
    //判断是否有新增的列
    NSMutableArray *noFields = [NSMutableArray new];
    for (MXField *field in table.fields) {
        BOOL has = NO;
        for (NSString *name in oldFields) {
            if ([field.name isEqualToString:name]) {
                has = YES;break;
            }
        }
        if (!has) [noFields addObject:field];
    }
    if (!noFields.count) return;
    
    NSMutableArray *newFields = [NSMutableArray arrayWithArray:oldFields];
    //更新
    for (int i = 0; i < noFields.count; i++) {
        MXField *field = [noFields objectAtIndex:i];
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN '%@' %@",table.name, field.name, field.type];
        if ([db executeUpdate:sql]) {
            [newFields addObject:field.name];
        }
    }
    [self.dbCaches setObject:newFields forKey:table.name];
}

- (void)createOrUpdateTable:(MXTable *)table db:(FMDatabase *)db
{
    [self createTable:table db:db];
    [self updateTable:table db:db];
}

#pragma mark
#pragma mark === save or update ===

//保存
- (BOOL)save:(MXRecord *)record
{
    if (!record) return NO;
    __block success = NO;
    [self.saveQueue inDatabase:^(FMDatabase *db) {
        
        [self createOrUpdateTable:record.table db:db];
        
        BOOL exist = [self recordDidExists:record db:db];
        if (exist) {
            success = [self update:record db:db];
        }
        else {
            success = [self insert:record db:db];
        }
    }];
    return success;
}

//更新
- (BOOL)update:(MXRecord *)record db:(FMDatabase *)db
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE '%@' SET ", record.table.name];
    
    NSMutableArray *argArray = [NSMutableArray new];
    for (NSInteger i = 0; i < record.fieldValues.count; i++) {
        MXFieldValue *fv = record.fieldValues[i];
        if (!fv.value || [fv.value isKindOfClass:[NSNull class]]) continue;
        if ([fv.name isEqualToString:record.pkFieldValue.name]) continue;
        sql = [sql stringByAppendingFormat:@"'%@' = ?,", fv.name];
        [argArray addObject:fv.value];
    }
    if ([sql hasSuffix:@","]) sql = [sql substringToIndex:sql.length - 1];
    sql = [sql stringByAppendingFormat:@" WHERE \"%@\" = ?", record.pkFieldValue.name];
    [argArray addObject:record.pkFieldValue.value];
    return [db executeUpdate:sql withArgumentsInArray:argArray];
}

//数据是否已存在
- (BOOL)recordDidExists:(MXRecord *)record db:(FMDatabase *)db
{
    MXTable *table = record.table;
    NSString *sql = [NSString stringWithFormat:@"SELECT (\"%@\") from '%@' WHERE \"%@\" = ?" , table.pkField.name, table.name, table.pkField.name];
    [db setLogsErrors:NO];
    FMResultSet *rs = [db executeQuery:sql, record.pkFieldValue.value];
    [db setLogsErrors:YES];
    BOOL exists = [rs next];
    [rs close];
    return exists;
}

//无条件强势插入
- (BOOL)insert:(MXRecord *)record db:(FMDatabase *)db
{
    MXTable *table = record.table;
    NSString *sql = [NSString stringWithFormat:@"INSERT OR IGNORE INTO '%@' (",table.name];
    NSString *vFlag = @" VALUES (";
    NSMutableArray *argArray = [NSMutableArray new];
    for (int i = 0; i < record.fieldValues.count; i++) {
        MXFieldValue *fv = record.fieldValues[i];
        if (!fv.value || [fv.value isKindOfClass:[NSNull class]]) continue;
        if ([fv.name isEqualToString:record.pkFieldValue.name]) {
            if ([fv.type isEqualToString:MXTInt] || [fv.type isEqualToString:MXTLong] || [fv.type isEqualToString:MXTNumber]) {
                long long val = [fv.value longLongValue];
                if (val == 0) continue;
            }
        }
        sql = [sql stringByAppendingFormat:@"'%@',", fv.name];
        vFlag = [vFlag stringByAppendingFormat:@"?,"];
        [argArray addObject:fv.value];
    }
    if ([sql hasSuffix:@","]) sql = [sql substringToIndex:sql.length - 1];
    if ([vFlag hasSuffix:@","]) vFlag = [vFlag substringToIndex:vFlag.length - 1];
    sql = [sql stringByAppendingString:@")"];
    vFlag = [vFlag stringByAppendingString:@")"];
    sql = [sql stringByAppendingString:vFlag];
    return [db executeUpdate:sql withArgumentsInArray:argArray];
}

#pragma mark
#pragma mark === query ===

- (NSArray *)query:(MXTable *)table fields:(NSArray *)fields condition:(NSString *)conditionString
{
    if (!table) return nil;
    __block NSArray *result;
    [self.queryQueue inDatabase:^(FMDatabase *db) {
        result = [self query:table fields:fields condition:conditionString db:db];
    }];
    return result;
}

//查询
- (NSArray *)query:(MXTable *)table fields:(NSArray *)fields condition:(NSString *)conditionString db:(FMDatabase *)db
{
    NSInteger count = fields.count;
    NSString *fid = count ? @"" : @"*";
    for (int i = 0; i < count; i++) {
        NSString *fname = fields[i];
        NSString *fStr = (i == count - 1) ? @"" : @",";
        fid = [fid stringByAppendingFormat:@" '%@'%@",fname,fStr];
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@%@",fid, table.name, conditionString ? conditionString : @""];
    [db setLogsErrors:NO];
    FMResultSet *rs = [db executeQuery:sql];
    [db setLogsErrors:YES];
    
    NSMutableArray *results = [NSMutableArray new];
    while ([rs next]) {
        NSInteger count = [rs columnCount];
        if (!count) continue;
        
        MXRecord *record = [[MXRecord alloc] initWithTable:table];
        
        NSMutableArray *fvs = [NSMutableArray new];
        for (int i = 0; i < count; i++) {
            MXFieldValue *fv = [MXFieldValue new];
            fv.name = [rs columnNameForIndex:i];
            fv.value = [rs objectForColumnIndex:i];
            [fvs addObject:fv];
        }
        [results addObject:record];
    }
    [rs close];
    return results;
}

#pragma mark
#pragma mark ==== count ====

//查询数量
- (int)count:(NSString *)tableName condition:(NSString *)conditionString
{
    __block int count = 0;
    conditionString = conditionString ? conditionString : @"";
    [self.countQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@%@", tableName, conditionString ? conditionString : @""];
        [db setLogsErrors:NO];
        FMResultSet *rs = [db executeQuery:sql];
        [db setLogsErrors:YES];
        while ([rs next]) {
            count = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return count;
}

#pragma mark
#pragma mark ==== delete ====

//删除
- (BOOL)delete:(NSString *)tableName condition:(NSString *)conditionString
{
    __block BOOL success = NO;
    [self.deleteQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@%@", tableName, conditionString ? conditionString : @""];
        success = [db executeUpdate:sql];
    }];
    return success;
}


@end
