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

@end

@interface MXRecord : NSObject

@property (nonatomic, strong) MXTable *table;

@property (nonatomic, strong) MXFieldValue *pkFieldValue;

@property (nonatomic, strong) NSArray *fieldValues;

- (instancetype)initWithTable:(MXTable *)table;

@end