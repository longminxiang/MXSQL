//
//  Man.m
//
//  Created by longminxiang on 13-10-10.
//  Copyright (c) 2013年 longminxiang. All rights reserved.
//

#import "Man.h"

@implementation Man

@end

@implementation House

@end

@implementation Houses

+ (NSString *)keyField
{
    return @"value";
}

+ (NSArray *)includeFields
{
    return @[@"house"];
}

@end