//
//  MXSqliteObjCache.m
//  MXSQLDemo
//
//  Created by eric on 15/4/24.
//  Copyright (c) 2015年 longminxiang. All rights reserved.
//

#import "MXSqliteObjCache.h"
#import "MXTable.h"

@interface MXSqliteObjCache : NSObject

@property (nonatomic, readonly) NSMutableDictionary *fieldsCache;
@property (nonatomic, readonly) NSMutableDictionary *tableCache;

@end

@implementation MXSqliteObjCache
@synthesize  fieldsCache = _fieldsCache;

+ (instancetype)shareInstance
{
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self class] new];
    });
    return object;
}

- (id)init
{
    if (self = [super init]) {
        _fieldsCache = [NSMutableDictionary new];
    }
    return self;
}

- (void)cacheFields:(NSArray *)fields forClass:(Class)cls
{
    NSString *key = [self cacheKeyForClass:cls];
    if (fields.count && key) {
        self.fieldsCache[key] = fields;
    }
}

- (NSArray *)fieldsCacheWithClass:(Class)cls
{
    NSString *key = [self cacheKeyForClass:cls];
    NSArray *fields = self.fieldsCache[key];
    return fields;
}

- (void)cacheTable:(MXTable *)table forClass:(Class)cls
{
    NSString *key = [self cacheKeyForClass:cls];
    if (table && key) {
        self.tableCache[key] = table;
    }
}

- (MXTable *)tableCacheWithClass:(Class)cls
{
    NSString *key = [self cacheKeyForClass:cls];
    MXTable *table = self.tableCache[key];
    return table;
}

- (NSString *)cacheKeyForClass:(Class)cls
{
    if (!cls) return nil;
    NSString *cacheKey = [NSString stringWithFormat:@"MXSqlFieldCache_%@", [cls description]];
    return cacheKey;
}

@end

@implementation NSObject (MXSqliteObjCache)

+ (void)cacheFields:(NSArray *)fields
{
    [[MXSqliteObjCache shareInstance] cacheFields:fields forClass:self];
}

+ (NSArray *)fieldsCache
{
    return [[MXSqliteObjCache shareInstance] fieldsCacheWithClass:self];
}

+ (void)cacheTable:(MXTable *)table
{
    [[MXSqliteObjCache shareInstance] cacheTable:table forClass:self];
}

+ (MXTable *)tableCache
{
    return [[MXSqliteObjCache shareInstance] tableCacheWithClass:self];
}

@end
