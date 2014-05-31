//
//  MXField.h
//
//  Created by longminxiang on 14-1-16.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MXTString   @"text"
#define MXTDate     @"date"
#define MXTNumber   @"number"
#define MXTInt      @"integer"
#define MXTFloat    @"float"
#define MXTDouble   @"double"
#define MXTBOOL     @"boolean"
#define MXTLong     @"integer"
#define MXTData     @"blob"

#pragma mark === MXField ===

@interface MXField : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *type;

@property (nonatomic, strong) id value;

@end

#pragma mark === MXFieldCache ===

@interface MXFieldCache : NSObject

+ (void)setFieldsCache:(NSArray *)array forClass:(Class)class;

+ (NSArray *)fieldsCacheForClass:(Class)class;

@end

#pragma mark === NSObject Category for MXField ===

@interface NSObject (MXField)

+ (NSArray *)mxFields;

- (NSArray *)mxFields;

+ (MXField *)mxFieldWithName:(NSString *)fieldName;

- (MXField *)mxFieldWithName:(NSString *)fieldName;

@end
