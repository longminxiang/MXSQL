//
//  MXTable.h
//
//  Created by longminxiang on 14-1-27.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXField.h"

@interface MXTable : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) MXField *keyField;

@property (nonatomic, strong) NSMutableArray *fields;

@property (nonatomic, strong) NSArray *ignoreFields;

+ (instancetype)tableForClass:(Class)class;

+ (instancetype)tableForObject:(id)object;

- (MXField *)fieldForKey:(NSString *)key;

@end
