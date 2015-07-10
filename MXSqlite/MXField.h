//
//  MXField.h
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define MXTString   @"text"
#define MXTDate     @"date"
#define MXTNumber   @"number"
#define MXTInt      @"integer"
#define MXTFloat    @"float"
#define MXTDouble   @"double"
#define MXTBOOL     @"boolean"
#define MXTLong     @"integer"
#define MXTData     @"blob"

#define IDX_FIELD_NAME  @"idx"

#pragma mark === MXField ===

@interface MXField : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) id value;

- (BOOL)isIdxField;

@end
