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
        NSString *pstr = [field isIdxField] ? @" PRIMARY KEY AUTOINCREMENT" : @"";
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
- (int64_t)save:(MXTable *)table
{
    __block int64_t idx = 0;
    if (!table) return idx;
    [self.saveQueue inDatabase:^(FMDatabase *db) {
        
        [self createOrUpdateTable:table db:db];
        
        int64_t tidx = [table.idxField.value longLongValue];
        BOOL excludeIdx = NO;
        if (![table isKeyFieldEmpty]) {
            idx = [self update:table withField:table.keyField db:db];
            excludeIdx = YES;
        }
        else if (tidx > 0) {
            idx = [self update:table withField:table.idxField db:db];
        }
        //插入
        if (idx <= 0) idx = [self insert:table excludeIdx:excludeIdx inDB:db];
    }];
    return idx;
}

//更新
- (int64_t)update:(MXTable *)table withField:(MXField *)field db:(FMDatabase *)db
{
    [db setLogsErrors:NO];
    int64_t idx = [self table:table didExist:field db:db];
    [db setLogsErrors:YES];
    if (idx <= 0) return 0;
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE '%@' SET ",table.name];
    NSInteger fieldsCount = table.fields.count;
    NSMutableArray *argArray = [NSMutableArray new];
    for (NSInteger i = 0; i < fieldsCount; i++) {
        MXField *f = table.fields[i];
        if (!f.value || [f.value isKindOfClass:[NSNull class]]) continue;
        if ([f.name isEqualToString:IDX_FIELD_NAME]) {
            f.value = @(idx);
        }
        sql = [sql stringByAppendingFormat:@"'%@' = ?,", f.name];
        [argArray addObject:f.value];
    }
    if ([sql hasSuffix:@","]) sql = [sql substringToIndex:sql.length - 1];
    sql = [sql stringByAppendingFormat:@" WHERE \"%@\" = ?",field.name];
    [argArray addObject:field.value];
    [db executeUpdate:sql withArgumentsInArray:argArray];
    return idx;
}

//数据是否已存在
- (int64_t)table:(MXTable *)table didExist:(MXField *)field db:(FMDatabase *)db
{
    int64_t idx = 0;
    NSString *sql = [NSString stringWithFormat:@"SELECT (\"%@\") from '%@' WHERE \"%@\" = ?" , IDX_FIELD_NAME, table.name, field.name];
    FMResultSet *rs = [db executeQuery:sql,field.value];
    while ([rs next]) {
        idx = [rs longLongIntForColumn:IDX_FIELD_NAME];
    }
    [rs close];
    return idx;
}

//无条件强势插入
- (int64_t)insert:(MXTable *)table excludeIdx:(BOOL)eidx inDB:(FMDatabase *)db
{
    NSString *sql = [NSString stringWithFormat:@"INSERT OR IGNORE INTO '%@' (",table.name];
    NSString *vFlag = @" VALUES (";
    NSMutableArray *argArray = [NSMutableArray new];
    for (int i = 0; i < table.fields.count; i++) {
        MXField *field = [table.fields objectAtIndex:i];
        id value = field.value;
        if (!value || [value isKindOfClass:[NSNull class]]) continue;
        if ([field.name isEqualToString:IDX_FIELD_NAME]) {
            if ([value longLongValue] <= 0 || eidx) continue;
        }
        sql = [sql stringByAppendingFormat:@"'%@',", field.name];
        vFlag = [vFlag stringByAppendingFormat:@"?,"];
        [argArray addObject:value];
    }
    if ([sql hasSuffix:@","]) sql = [sql substringToIndex:sql.length - 1];
    if ([vFlag hasSuffix:@","]) vFlag = [vFlag substringToIndex:vFlag.length - 1];
    sql = [sql stringByAppendingString:@")"];
    vFlag = [vFlag stringByAppendingString:@")"];
    sql = [sql stringByAppendingString:vFlag];
    [db executeUpdate:sql withArgumentsInArray:argArray];
    return [db lastInsertRowId];;
}

#pragma mark
#pragma mark === query ===

- (NSArray *)fresh:(MXTable *)table condition:(NSString *)conditionString
{
    if (!table) return nil;
    __block NSArray *result;
    [self.freshQueue inDatabase:^(FMDatabase *db) {
        result = [self query:table include:nil inDB:db condition:conditionString];
    }];
    return result;
}

- (NSArray *)query:(MXTable *)table include:(NSArray *)fields condition:(NSString *)conditionString
{
    if (!table) return nil;
    __block NSArray *result;
    [self.queryQueue inDatabase:^(FMDatabase *db) {
        result = [self query:table include:fields inDB:db condition:conditionString];
    }];
    return result;
}

//查询
- (NSArray *)query:(MXTable *)table include:(NSArray *)fields inDB:(FMDatabase *)db condition:(NSString *)conditionString
{
    NSMutableArray *result = [NSMutableArray new];

    NSInteger count = fields.count;
    NSString *fid = @"";
    if (!count) {
        fid = @"*";
    }
    else {
        for (int i = 0; i < count; i++) {
            NSString *fname = fields[i];
            NSString *fStr = (i == count - 1) ? @"" : @",";
            fid = [fid stringByAppendingFormat:@" '%@'%@",fname,fStr];
        }
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@%@",fid,table.name,conditionString ? conditionString : @""];
    [db setLogsErrors:NO];
    FMResultSet *rs = [db executeQuery:sql];
    [db setLogsErrors:YES];
    while ([rs next]) {
        NSMutableArray *fields = [NSMutableArray new];
        for (int i = 0; i < [rs columnCount]; i++) {
            MXField *field = [MXField new];
            field.name = [rs columnNameForIndex:i];
            id value = [rs objectForColumnIndex:i];
            field.value = value;
            [fields addObject:field];
        }
        if (fields) [result addObject:fields];
    }
    [rs close];
    if (!result.count) result = nil;
    return result;
}

#pragma mark
#pragma mark ==== count ====

//查询数量
- (int)count:(NSString *)table condition:(NSString *)conditionString
{
    __block int count = 0;
    conditionString = conditionString ? conditionString : @"";
    [self.countQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@%@",table,conditionString ? conditionString : @""];
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
- (BOOL)delete:(NSString *)table condition:(NSString *)conditionString
{
    __block BOOL success = NO;
    [self.deleteQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@%@",table,conditionString ? conditionString : @""];
        success = [db executeUpdate:sql];
    }];
    return success;
}


@end
