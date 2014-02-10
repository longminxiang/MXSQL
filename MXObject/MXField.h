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

@interface MXField : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *type;

@property (nonatomic, strong) id value;

+ (NSMutableArray *)fieldsForObject:(id)object ignoreFields:(NSArray *)ignoreFields;

+ (NSMutableArray *)fieldsNameForClass:(Class)class ignoreFields:(NSArray *)ignoreFields;

+ (NSString *)typeOfField:(NSString *)fieldName class:(Class)class;

@end
