//
//  MXTable.m
//
//  Created by longminxiang on 14-1-27.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXTable.h"
#import "NSObject+MXSQL.h"

@interface MXTable ()

@property (nonatomic, strong) NSCache *tableCache;

@end

@implementation MXTable

+ (instancetype)shareTable
{
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self class] new];
    });
    return object;
}

+ (instancetype)tableForClass:(Class)class
{
    NSString *className = [class description];
    MXTable *shareTable = [self shareTable];
    NSString *cacheKey = [NSString stringWithFormat:@"MXTableCache_%@",className];
    id cache = [shareTable.tableCache objectForKey:cacheKey];
    if (cache) return cache;
    
    MXTable *table = [MXTable new];
    table.name = className;
    table.ignoreFields = [class ignoreFields];
    table.fields = [MXField fieldsNameForClass:class ignoreFields:table.ignoreFields];
    table.keyField = [table fieldForKey:[class keyField]];
    [shareTable.tableCache setObject:table forKey:cacheKey];
    
    return table;
}

+ (instancetype)tableForObject:(id)object
{
    Class class = [object class];
    MXTable *table = [self tableForClass:class];
    table.fields = [MXField fieldsForObject:object ignoreFields:table.ignoreFields];
    table.keyField = [table fieldForKey:[class keyField]];
    return table;
}

- (MXField *)fieldForKey:(NSString *)key
{
    for (MXField *field in self.fields) {
        if ([field.name isEqualToString:key]) {
            return field;
        }
    }
    return nil;
}

@end
