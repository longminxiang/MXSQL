//
//  MXField.m
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXField.h"

#pragma mark === MXField ===

@implementation MXField

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"%@: %@: %@", self.name, self.type, self.value];
    return des;
}

- (BOOL)isIdxField
{
    return [self.name isEqualToString:IDX_FIELD_NAME];
}

@end
