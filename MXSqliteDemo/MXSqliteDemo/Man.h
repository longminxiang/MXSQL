//
//  Man.h
//
//  Created by longminxiang on 13-10-10.
//  Copyright (c) 2013年 longminxiang. All rights reserved.
//

#import "MXSqliteObject.h"

@interface Man : MXSqliteObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) double money;
@property (nonatomic, assign) BOOL gfs;
@property (nonatomic, strong) NSMutableArray *houses;
@property (nonatomic, copy) NSDate *brithday;
@property (nonatomic, copy) NSString *nick;
@property (nonatomic, copy) NSString *nick1;
@property (nonatomic, copy) NSString *nick2;
@property (nonatomic, assign) int xxx;

@end

@interface Women : Man

@property (nonatomic, copy) Man *ma;

@end

@interface House : NSObject

@property (nonatomic, assign) int64_t ownerIndex;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int value;

@end

@interface Houses : NSObject

@property (nonatomic, assign) int ownerIndex;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int value;
@property (nonatomic, assign) int value1;
@property (nonatomic, assign) int value2;
@property (nonatomic, assign) int value3;

@property (nonatomic, strong) House *house;

@end