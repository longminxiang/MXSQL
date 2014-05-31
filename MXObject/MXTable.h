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

@property (nonatomic, strong) MXField *keyField;

@property (nonatomic, strong) NSArray *fields;

- (instancetype)clone;

@end

#pragma mark === MXTableCaache ===

@interface MXTableCache : NSObject

+ (void)setTableCache:(MXTable *)table forClass:(Class)class;

+ (MXTable *)tableCacheForClass:(Class)class;

@end

#pragma mark === NSObject Category for MXTable ===

@interface NSObject (MXTable)

+ (NSString *)keyField;

+ (MXTable *)mxTable;

- (MXTable *)mxTable;

@end