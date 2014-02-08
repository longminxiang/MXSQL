//
//  MXField.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXField.h"
#import <objc/runtime.h>

@interface MXField ()

@property (nonatomic, strong) NSCache *fieldCache;

@end

@implementation MXField

+ (instancetype)shareField
{
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self class] new];
    });
    return object;
}

//解析类型
+ (NSString *)sqlTypeFromProperty:(objc_property_t)propertie
{
    NSString *propertyType = [NSString stringWithUTF8String:property_getAttributes(propertie)];
    propertyType = [[propertyType componentsSeparatedByString:@","] objectAtIndex:0];
    if ([propertyType isEqualToString:@"T@\"NSString\""]) return MXTString;
    if ([propertyType isEqualToString:@"T@\"NSDate\""]) return MXTDate;
    if ([propertyType isEqualToString:@"T@\"NSNumber\""]) return MXTNumber;
    if ([propertyType isEqualToString:@"Ti"]) return MXTInt;
    if ([propertyType isEqualToString:@"Tl"]) return MXTInt;
    if ([propertyType isEqualToString:@"Tq"]) return MXTLong;
    if ([propertyType isEqualToString:@"Tf"]) return MXTFloat;
    if ([propertyType isEqualToString:@"Td"]) return MXTDouble;
    if ([propertyType isEqualToString:@"Tc"]) return MXTBOOL;
    return nil;
}

+ (BOOL)stringArray:(NSArray *)array isContainString:(NSString *)string
{
    for (id str in array) {
        if ([str isKindOfClass:[NSString class]]) {
            if ([string isEqualToString:str]) {
                return YES;
            }
        }
    }
    return NO;
}

//取本类及父类的属性变量及其值
+ (NSMutableArray *)fieldsForObject:(id)object ignoreFields:(NSArray *)ignoreFields
{
    return [self fieldsForObjectOrClass:object isObject:YES ignoreFields:ignoreFields];
}

//取本类及父类的属性变量名
+ (NSMutableArray *)fieldsNameForClass:(Class)class ignoreFields:(NSArray *)ignoreFields
{
    return [self fieldsForObjectOrClass:class isObject:NO ignoreFields:ignoreFields];
}

+ (NSMutableArray *)fieldsForObjectOrClass:(id)objectOrClass isObject:(BOOL)isObject ignoreFields:(NSArray *)ignoreFields
{
    Class class = isObject ? [objectOrClass class] : objectOrClass;
    NSString *className = [class description];
    
    MXField *shareField = [self shareField];
    NSString *cacheKey = [NSString stringWithFormat:@"MXFieldCache_%@",className];
    
    if (!isObject) {
        id cache = [shareField.fieldCache objectForKey:cacheKey];
        if (cache) return cache;
    }
    
    u_int count;
    objc_property_t *properties = class_copyPropertyList(class, &count);
    
    NSMutableArray *fieldArray = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        MXField *field = [MXField new];
        objc_property_t property = properties[i];
        NSString *type = [self sqlTypeFromProperty:property];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        BOOL isIgnore = [self stringArray:ignoreFields isContainString:propertyName];
        if (type && !isIgnore) {
            field.type = type;
            field.name = propertyName;
            if (isObject) {
                id value = [objectOrClass valueForKey:propertyName];
                if ([type isEqualToString:MXTString] && !value)
                    value = @"";
                field.value = value;
            }
            [fieldArray insertObject:field atIndex:0];
        }
    }
    free(properties);
    
    if (!isObject) {
        [shareField.fieldCache setObject:fieldArray forKey:cacheKey];
    }
    return fieldArray;
}

@end
