//
//  MXField.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXField.h"
#import <objc/runtime.h>

#pragma mark === MXField ===

@implementation MXField

//解析类型
+ (NSString *)fieldTypeFromProperty:(objc_property_t)propertie
{
    if (!propertie) return nil;
    const char *pType = property_getAttributes(propertie);
    NSString *propertyType = [NSString stringWithUTF8String:pType];
    NSArray *coms = [propertyType componentsSeparatedByString:@","];
    
    //如果是readonlyo类型的，忽略；
    if (coms.count >= 2) {
        NSString *rtype = coms[1];
        if ([rtype isEqualToString:@"R"]) return nil;
    }
    
    propertyType = [coms objectAtIndex:0];
    if ([propertyType isEqualToString:@"T@\"NSString\""]) return MXTString;
    if ([propertyType isEqualToString:@"T@\"NSDate\""]) return MXTDate;
    if ([propertyType isEqualToString:@"T@\"NSData\""]) return MXTData;
    if ([propertyType isEqualToString:@"T@\"NSNumber\""]) return MXTNumber;
    if ([propertyType isEqualToString:@"Ti"]) return MXTInt;
    if ([propertyType isEqualToString:@"Tl"]) return MXTInt;
    if ([propertyType isEqualToString:@"Tq"]) return MXTLong;
    if ([propertyType isEqualToString:@"Tf"]) return MXTFloat;
    if ([propertyType isEqualToString:@"Td"]) return MXTDouble;
    if ([propertyType isEqualToString:@"Tc"]) return MXTBOOL;
    return nil;
}

@end

#pragma mark === MXFieldCache ===

@interface MXFieldCache ()

@property (nonatomic, strong) NSCache *classFieldCache;

@end

@implementation MXFieldCache

+ (instancetype)shareFieldCache
{
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self class] new];
    });
    return object;
}

- (NSCache *)classFieldCache
{
    if (!_classFieldCache) _classFieldCache = [NSCache new];
    return _classFieldCache;
}

+ (void)setFieldsCache:(NSArray *)array forClass:(Class)class
{
    [[self shareFieldCache] setFieldsCache:array forClass:class];
}

- (void)setFieldsCache:(NSArray *)array forClass:(Class)class
{
    NSString *key = [self cacheKeyForClass:class];
    [self.classFieldCache setObject:array forKey:key];
}

+ (NSArray *)fieldsCacheForClass:(Class)class
{
    return [[self shareFieldCache] fieldsCacheForClass:class];
}

- (NSArray *)fieldsCacheForClass:(Class)class
{
    NSString *key = [self cacheKeyForClass:class];
    NSArray *array = [self.classFieldCache objectForKey:key];
    return array;
}

- (NSString *)cacheKeyForClass:(Class)class
{
    if (!class) return nil;
    NSString *cacheKey = [NSString stringWithFormat:@"MXFieldCache_%@",[class description]];
    return cacheKey;
}

@end

#pragma mark === NSObject Category for MXField ===

@implementation NSObject (MXField)

+ (NSArray *)mxFields
{
    NSArray *cache = [MXFieldCache fieldsCacheForClass:self];
    if (cache) return cache;
    
    u_int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    
    NSMutableArray *fields = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        MXField *field = [MXField new];
        objc_property_t property = properties[i];
        NSString *type = [MXField fieldTypeFromProperty:property];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        if (type) {
            field.type = type;
            field.name = propertyName;
            [fields insertObject:field atIndex:0];
        }
    }
    free(properties);
    
    [MXFieldCache setFieldsCache:fields forClass:self];
    return fields;
}

- (NSArray *)mxFields
{
    NSArray *fields = [[self class] mxFields];
    for (MXField *field in fields) {
        id value = [self valueForKey:field.name];
        field.value = value;
    }
    return fields;
}

+ (MXField *)mxFieldWithName:(NSString *)fieldName
{
    NSArray *fields = [self mxFields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:fieldName]) {
            return field;
        }
    }
    return nil;
}

- (MXField *)mxFieldWithName:(NSString *)fieldName
{
    NSArray *fields = [self mxFields];
    for (MXField *field in fields) {
        if ([field.name isEqualToString:fieldName]) {
            return field;
        }
    }
    return nil;
}

@end


