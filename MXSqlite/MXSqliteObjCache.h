//
//  MXSqliteObjCache.h
//  MXSQLDemo
//
//  Created by eric on 15/4/24.
//  Copyright (c) 2015年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MXTable;

@interface NSObject (MXSqliteObjCache)

+ (void)cacheFields:(NSArray *)fields;

+ (NSArray *)fieldsCache;

+ (void)cacheTable:(MXTable *)table;

+ (MXTable *)tableCache;

@end