//
//  MXCondition.m
//
//  Created by longminxiang on 13-10-11.
//  Copyright (c) 2013年 longminxiang. All rights reserved.
//

#import "MXCondition.h"

typedef enum{
    MXConditionWhere = 0,
    MXConditionLimit,
    MXConditionOrderBy
} MXConditionType;

@interface MXCondition ()

@property (nonatomic, copy) NSString *conditionString;
@property (nonatomic, assign) MXConditionType type;

@end

@implementation MXCondition

+ (MXCondition *)whereKey:(NSString *)key equalTo:(id)object
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionWhere;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\" %@ '%@'",key,@"=",object];
    return condition;
}

+ (MXCondition *)whereKey:(NSString *)key lessThan:(id)object
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionWhere;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\" %@ '%@'",key,@"<",object];
    return condition;
}

+ (MXCondition *)whereKey:(NSString *)key lessThanOrEqualTo:(id)object
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionWhere;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\" %@ '%@'",key,@"<=",object];
    return condition;
}

+ (MXCondition *)whereKey:(NSString *)key greaterThan:(id)object
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionWhere;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\" %@ '%@'",key,@">",object];
    return condition;
}

+ (MXCondition *)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionWhere;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\" %@ '%@'",key,@">=",object];
    return condition;
}

+ (MXCondition *)limitBeganRow:(int)beganRow count:(int)count
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionLimit;
    condition.conditionString = [NSString stringWithFormat:@" LIMIT %d,%d",beganRow,count];
    return condition;
}

+ (MXCondition *)orderByAscending:(NSString *)key
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionOrderBy;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\"",key];
    return condition;
}

+ (MXCondition *)orderByDescending:(NSString *)key
{
    MXCondition *condition = [MXCondition new];
    condition.type = MXConditionOrderBy;
    condition.conditionString = [NSString stringWithFormat:@"\"%@\" DESC",key];
    return condition;
}

@end

@implementation MXCondition (condition)

+ (NSString *)conditionStringWithConditions:(NSArray *)conditions
{
    NSMutableArray *whereCondition = [NSMutableArray new];
    NSMutableArray *orderbyCondition = [NSMutableArray new];
    MXCondition *limitCondition;
    for (MXCondition *condition in conditions) {
        switch (condition.type) {
            case MXConditionWhere:
                [whereCondition addObject:condition];
                break;
            case MXConditionLimit:
                if (!limitCondition) limitCondition = condition;
                break;
            case MXConditionOrderBy:
                [orderbyCondition addObject:condition];
                break;
            default:
                break;
        }
    }
    NSString *whereConditionString = @"";
    for (int i = 0; i < whereCondition.count; i++) {
        MXCondition *condition = [whereCondition objectAtIndex:i];
        NSString *cd = condition.isOr ? @"OR" : @"AND";
        NSString *cString = i == 0 ? @"WHERE" : cd;
        whereConditionString = [NSString stringWithFormat:@"%@ %@ %@",whereConditionString,cString, condition.conditionString];
    }
    NSString *orderbyConditionString = @"";
    for (int i = 0; i < orderbyCondition.count; i++) {
        MXCondition *condition = [orderbyCondition objectAtIndex:i];
        NSString *cString = i == 0 ? @"ORDER BY" : @"AND";
        orderbyConditionString = [NSString stringWithFormat:@" %@ %@",cString, condition.conditionString];
    }
    NSString *conditionString = [whereConditionString stringByAppendingString:orderbyConditionString];
    if (limitCondition) {
        conditionString = [conditionString stringByAppendingString:limitCondition.conditionString];
    }
    if (!conditionString || [conditionString isKindOfClass:[NSNull class]]) conditionString = @"";
    return conditionString;
}

@end

