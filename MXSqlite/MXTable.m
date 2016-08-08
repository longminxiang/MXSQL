//
//  MXTable.m
//
//  Created by longminxiang on 14-1-27.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXTable.h"

#pragma mark === MXTable ===

@implementation MXTable

@end


@implementation MXRecord

- (instancetype)initWithTable:(MXTable *)table
{
    if (self = [super init]) {
        self.table = table;
        self.pkFieldValue = [MXFieldValue instanceWithField:table.pkField];
    }
    return self;
}

@end