//
//  MXField.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXField.h"

#pragma mark === MXField ===

@implementation MXField

+ (instancetype)defaultPkField
{
    static MXField *field;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        field = [MXField new];
        field.name = IDX_FIELD_NAME;
        field.type = MXTLong;
    });
    return field;
}

@end

@implementation MXFieldValue

+ (instancetype)instanceWithField:(MXField *)field
{
    MXFieldValue *fv = [MXFieldValue new];
    fv.name = field.name;
    fv.type = field.type;
    return fv;
}

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"%@: %@: %@", self.name, self.type, self.value];
    return des;
}

@end
