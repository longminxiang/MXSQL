//
//  MXSQL.m
//
//  Created by longminxiang on 14-1-23.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXSQL.h"

#define MXSQL_DEFAULT_DB_PATH @"MXSQL/MXDB"

@interface MXSQL ()

@property (nonatomic, copy) NSString *dbPath;
@property (nonatomic, assign) NSSearchPathDirectory dbDirectory;

@property (nonatomic, strong) NSMutableArray *tableNames;
@property (nonatomic, strong) NSMutableDictionary *fieldNameDics;

@property (nonatomic, strong) FMDatabaseQueue *saveQueue, *queryQueue, *freshQueue;
@property (nonatomic, strong) FMDatabaseQueue *countQueue, *deleteQueue;

@end

@implementation MXSQL

+ (instancetype)sharedMXSQL
{
    static MXSQL *mxsql = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mxsql = [MXSQL new];
        [mxsql setDatabasePath:MXSQL_DEFAULT_DB_PATH directory:NSCachesDirectory];
    });
    return mxsql;
}

- (id)init
{
    if (self = [super init]) {
        self.tableNames = [NSMutableArray new];
        self.fieldNameDics = [NSMutableDictionary new];
    }
    return self;
}

- (void)setDatabasePath:(NSString *)path directory:(NSSearchPathDirectory)directory
{
    if ([path isEqualToString:self.dbPath] && directory == self.dbDirectory) return;
    self.dbPath = path;
    self.dbDirectory = directory;
    
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
    
    _currentDBPath = [path copy];
    self.saveQueue = [FMDatabaseQueue databaseQueueWithPath:self.currentDBPath];
    self.queryQueue = [FMDatabaseQueue databaseQueueWithPath:self.currentDBPath];
    self.countQueue = [FMDatabaseQueue databaseQueueWithPath:self.currentDBPath];
    self.deleteQueue = [FMDatabaseQueue databaseQueueWithPath:self.currentDBPath];
    self.freshQueue = [FMDatabaseQueue databaseQueueWithPath:self.currentDBPath];
    
    [self.tableNames removeAllObjects];
    [self.fieldNameDics removeAllObjects];
    [self.saveQueue inDatabase:^(FMDatabase *db) {
        NSArray *tables = [self tableNamesInDB:db];
        [self.tableNames addObjectsFromArray:tables];
        for (NSString *tbName in tables) {
            NSArray *fields = [self fieldNamesFromTable:tbName inDB:db];
            [self.fieldNameDics setObject:fields forKey:tbName];
        }
    }];
}

- (NSArray *)tableNamesInDB:(FMDatabase *)db
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

- (NSArray *)fieldNamesFromTable:(NSString *)table inDB:(FMDatabase *)db
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

#pragma mark === current table ===

- (void)createTable:(MXTable *)table inDB:(FMDatabase *)db
{
    if ([db tableExists:table.name]) return;
    NSMutableArray *nfields = [NSMutableArray new];
    MXField *field = [MXField new];
    field.name = MXSQL_INDEX;
    field.type = MXTInt;
    [nfields addObject:field];
    [nfields addObjectsFromArray:table.fields];
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (",table.name];
    for (int i = 0; i < nfields.count; i++) {
        MXField *field = [nfields objectAtIndex:i];
        NSString *fString = (i == nfields.count - 1) ? @")" : @",";
        if ([field.name isEqualToString:MXSQL_INDEX]) {
            sql = [sql stringByAppendingFormat:@"'%@' %@ PRIMARY KEY AUTOINCREMENT%@",field.name,field.type,fString];
        }
        else {
            sql = [sql stringByAppendingFormat:@"'%@' %@%@",field.name,field.type,fString];
        }
    }
    [db executeUpdate:sql];
}

- (void)updateTable:(MXTable *)table inDB:(FMDatabase *)db
{
    NSArray *ofieldNames = [self.fieldNameDics objectForKey:table.name];
    if (!ofieldNames.count) {
        [self.tableNames addObject:table.name];
        NSArray *fields = [self fieldNamesFromTable:table.name inDB:db];
        [self.fieldNameDics setObject:fields forKey:table.name];
        return;
    }
    
    NSMutableArray *noneFields = [NSMutableArray new];
    for (MXField *field in table.fields) {
        BOOL has = NO;
        for (NSString *ofieldName in ofieldNames) {
            if ([field.name isEqualToString:ofieldName]) {
                has = YES;break;
            }
        }
        if (!has) [noneFields addObject:field];
    }
    if (noneFields.count) {
        for (int i = 0; i < noneFields.count; i++) {
            MXField *field = [noneFields objectAtIndex:i];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN '%@' %@ DEFAULT '%@'",table.name,field.name,field.type,field.value];
            [db executeUpdate:sql];
        }
        NSArray *fields = [self fieldNamesFromTable:table.name inDB:db];
        [self.fieldNameDics setObject:fields forKey:table.name];
    }
}

#pragma mark === save or update ===

//插入
- (int64_t)save:(MXTable *)table
{
    __block int64_t index = -1;
    if (!table) return index;
    [self.saveQueue inDatabase:^(FMDatabase *db) {
        
        //查询是否已建表，如无，执行建表操作
        [self createTable:table inDB:db];
        
        //查询是否有新加列，如有，执行添加列操作
        [self updateTable:table inDB:db];
        
        //执行更新操作
        index = [self update:table inDB:db];
        
        //插入
        if (index == -1) index = [self saveOnly:table inDB:db];
    }];
    return index;
}

//数据是否已存在
- (int64_t)table:(MXTable *)table inDB:(FMDatabase *)db
{
    int64_t exist = -1;
    if (!table.keyField || [table.keyField.name isEqualToString:@""]) {
        return exist;
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT (\"%@\") from '%@' WHERE \"%@\" = ?",MXSQL_INDEX,table.name,table.keyField.name];
    FMResultSet *rs = [db executeQuery:sql,table.keyField.value];
    while ([rs next]) {
        exist = [rs longLongIntForColumn:MXSQL_INDEX];
    }
    [rs close];
    return exist;
}

//更新
- (int64_t)update:(MXTable *)table inDB:(FMDatabase *)db
{
    //查询是否已有记录
    [db setLogsErrors:NO];
    int64_t index = [self table:table inDB:db];
    [db setLogsErrors:YES];
    if (index == -1) return -1;
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE '%@' SET ",table.name];
    int fieldsCount = table.fields.count;
    for (int i = 0; i < fieldsCount; i++) {
        MXField *field = [table.fields objectAtIndex:i];
        if ([field.type isEqualToString:MXTDate]) {
            NSTimeInterval time = [field.value timeIntervalSince1970];
            field.value = [NSNumber numberWithDouble:time];
        }
        NSString *fString = (i == fieldsCount - 1) ? @"" : @",";
        sql = [sql stringByAppendingFormat:@"'%@' = '%@'%@",field.name,field.value,fString];
    }
    sql = [sql stringByAppendingFormat:@" WHERE \"%@\" = ?",table.keyField.name];
    [db executeUpdate:sql,table.keyField.value];
    return index;
}

//无条件强势插入
- (int64_t)saveOnly:(MXTable *)table inDB:(FMDatabase *)db
{
    NSString *sql = [NSString stringWithFormat:@"INSERT OR IGNORE INTO '%@' (",table.name];
    NSString *vFlag = @" VALUES (";
    for (int i = 0; i < table.fields.count; i++) {
        MXField *field = [table.fields objectAtIndex:i];
        if ([field.type isEqualToString:MXTDate]) {
            NSTimeInterval time = [field.value timeIntervalSince1970];
            field.value = [NSNumber numberWithDouble:time];
        }
        NSString *fString = (i == table.fields.count - 1) ? @")" : @",";
        sql = [sql stringByAppendingFormat:@"'%@'%@",field.name,fString];
        vFlag = [vFlag stringByAppendingFormat:@"'%@'%@",field.value,fString];
    }
    sql = [sql stringByAppendingString:vFlag];
    [db executeUpdate:sql];
    return [db lastInsertRowId];
}

#pragma mark === query ===

- (NSArray *)fresh:(MXTable *)table condition:(NSString *)conditionString
{
    if (!table) return nil;
    __block NSArray *result;
    [self.freshQueue inDatabase:^(FMDatabase *db) {
        result = [self query:table field:nil inDB:db condition:conditionString];
    }];
    return result;
}

- (NSArray *)query:(MXTable *)table field:(NSString *)field condition:(NSString *)conditionString
{
    if (!table) return nil;
    __block NSArray *result;
    [self.queryQueue inDatabase:^(FMDatabase *db) {
        result = [self query:table field:field inDB:db condition:conditionString];
    }];
    return result;
}

//查询
- (NSArray *)query:(MXTable *)table field:(NSString *)field inDB:(FMDatabase *)db condition:(NSString *)conditionString
{
    NSMutableArray *result = [NSMutableArray new];
    
    NSString *fid = field ? field : @"*";
    
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

#pragma mark ==== count ====

//查询数量
- (int)count:(NSString *)table condition:(NSString *)conditionString
{
    __block int count = 0;
    conditionString = conditionString ? conditionString : @"";
    [self.countQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@%@",table,conditionString];
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

#pragma mark ==== delete ====

//删除
- (BOOL)delete:(NSString *)table condition:(NSString *)conditionString
{
    __block BOOL success = NO;
    [self.deleteQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@%@",table,conditionString];
        success = [db executeUpdate:sql];
        [db close];
    }];
    return success;
}

@end
