//
//  MXField.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXField.h"

#pragma mark === MXField ===

@implementation MXField

+ (instancetype)pkField
{
    MXField *field = [MXField new];
    field.name = IDX_FIELD_NAME;
    field.type = MXTLong;
    return field;
}

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"%@: %@: %@", self.name, self.type, self.value];
    return des;
}

@end
