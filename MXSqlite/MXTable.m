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
    table.pkField = self.pkField;
    NSArray *fields;
    if (self.fields) fields = [NSArray arrayWithArray:self.fields];
    table.fields = fields;
    return table;
}

@end


