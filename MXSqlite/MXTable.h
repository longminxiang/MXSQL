//
//  MXTable.h
//
//  Created by longminxiang on 14-1-27.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXField.h"

#pragma mark === MXTable ===

@interface MXTable : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) MXField *pkField;

@property (nonatomic, strong) NSArray *fields;

- (instancetype)clone;

@end