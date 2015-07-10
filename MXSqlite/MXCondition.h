//
//  MXCondition.h
//
//  Created by longminxiang on 13-10-11.
//  Copyright (c) 2013年 longminxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MXCondition : NSObject

@property (nonatomic, assign) BOOL isOr;

/* between condition */
+ (MXCondition *)whereKey:(NSString *)key between:(id)object and:(id)anobject;

/* equal condition */
+ (MXCondition *)whereKey:(NSString *)key equalTo:(id)object;
+ (MXCondition *)whereKey:(NSString *)key or:(BOOL)isOr equalTo:(id)object;

/* not equal condition */
+ (MXCondition *)whereKey:(NSString *)key notEqualTo:(id)object;

/* less condition */
+ (MXCondition *)whereKey:(NSString *)key lessThan:(id)object;
+ (MXCondition *)whereKey:(NSString *)key or:(BOOL)isOr lessThan:(id)object;

/* less or equal condition */
+ (MXCondition *)whereKey:(NSString *)key lessThanOrEqualTo:(id)object;

/* greater condition */
+ (MXCondition *)whereKey:(NSString *)key greaterThan:(id)object;

/* greater or equal condition */
+ (MXCondition *)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object;

/* limit condition */
+ (MXCondition *)limitBeganRow:(int)beganRow count:(int)count;

/* order by key ascending */
+ (MXCondition *)orderByAscending:(NSString *)key;

/* order by key descending */
+ (MXCondition *)orderByDescending:(NSString *)key;

@end

@interface MXCondition (condition)

+ (NSString *)conditionStringWithConditions:(NSArray *)conditions;

+ (NSString *)orEqualConditionStringForKey:(NSString *)key values:(NSArray *)values;

@end