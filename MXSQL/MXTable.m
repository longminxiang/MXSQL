//
//  MXTable.m
//
//  Created by longminxiang on 14-1-27.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXTable.h"

#pragma mark === MXTable ===

@implementation MXTable

- (instancetype)clone
{
    if (!self) return nil;
    MXTable *table = [MXTable new];
    table.name = self.name;
    table.keyField = self.keyField;
    NSArray *fields;
    if (self.fields) fields = [NSArray arrayWithArray:self.fields];
    table.fields = fields;
    return table;
}

@end

#pragma mark === MXTableCaache ===

@interface MXTableCache ()

@property (nonatomic, strong) NSCache *classTableCache;

@end

@implementation MXTableCache

+ (instancetype)shareTableCache
{
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self class] new];
    });
    return object;
}

- (NSCache *)classTableCache
{
    if (!_classTableCache) _classTableCache = [NSCache new];
    return _classTableCache;
}

+ (void)setTableCache:(MXTable *)table forClass:(Class)class
{
    [[self shareTableCache] setTableCache:table forClass:class];
}

- (void)setTableCache:(MXTable *)table forClass:(Class)class
{
    NSString *key = [self cacheKeyForClass:class];
    [self.classTableCache setObject:table forKey:key];
}

+ (MXTable *)tableCacheForClass:(Class)class
{
    return [[self shareTableCache] tableCacheForClass:class];
}

- (MXTable *)tableCacheForClass:(Class)class
{
    NSString *key = [self cacheKeyForClass:class];
    MXTable *table = [self.classTableCache objectForKey:key];
    return table;
}

- (NSString *)cacheKeyForClass:(Class)class
{
    if (!class) return nil;
    NSString *cacheKey = [NSString stringWithFormat:@"MXTableCache_%@",[class description]];
    return cacheKey;
}

@end

#pragma mark === NSObject Category for MXTable ===

@implementation NSObject (MXTable)

+ (NSString *)keyField
{
    return nil;
}

+ (MXTable *)mxTable
{
    MXTable *table = [MXTableCache tableCacheForClass:self];
    if (table) return table;
    
    table = [MXTable new];
    table.name = [self description];
    table.fields = [self mxFields];
    table.keyField = [self mxFieldWithName:[self keyField]];
    
    [MXTableCache setTableCache:table forClass:self];
    
    return table;
}

- (MXTable *)mxTable
{
    MXTable *table = [[self class] mxTable];
    table.fields = [self mxFields];
    table.keyField = [self mxFieldWithName:[[self class] keyField]];
    return table;
}

@end


