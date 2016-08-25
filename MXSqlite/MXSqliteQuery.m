//
//  MXSqliteQuery.m
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import "MXSqliteQuery.h"

@interface MXSqliteQueryOperatorItem : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) MXSqliteQueryOperator operator;
@property (nonatomic, strong) id value;
@property (nonatomic, assign) BOOL isOr;

@property (nonatomic, readonly) NSString *operatorFlag;

@end

@implementation MXSqliteQueryOperatorItem

+ (instancetype)initWithKey:(NSString *)key op:(MXSqliteQueryOperator)op val:(id)val
{
    MXSqliteQueryOperatorItem *item = [MXSqliteQueryOperatorItem new];
    item.key = key;
    item.operator = op;
    item.value = val;
    return item;
}

- (void)setOperator:(MXSqliteQueryOperator)operator
{
    _operator = operator;
    switch (operator) {
        case MXSqliteQueryOperatorEqual: _operatorFlag = @"="; break;
        case MXSqliteQueryOperatorLess: _operatorFlag = @"<"; break;
        case MXSqliteQueryOperatorGreater: _operatorFlag = @">"; break;
        case MXSqliteQueryOperatorNotEqual: _operatorFlag = @"!="; break;
        case MXSqliteQueryOperatorLessOrEqual: _operatorFlag = @"<="; break;
        case MXSqliteQueryOperatorGreaterOrEqual: _operatorFlag = @">="; break;
        default: break;
    }
}

- (NSString *)queryString
{
    NSString *string = [NSString stringWithFormat:@"\"%@\" %@ '%@'", self.key, self.operatorFlag, self.value];
    return string;
}

@end

@interface MXSqliteQuerySortItem : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) MXSqliteQuerySort sort;

@end

@implementation MXSqliteQuerySortItem

- (NSString *)queryString
{
    NSString *string = [NSString stringWithFormat:@"\"%@\" %@", self.key, self.sort == MXSqliteQuerySortDescending ? @"DESC" : @""];
    return string;
}

@end


@interface MXSqliteQueryLimitItem : NSObject

@property (nonatomic, assign) NSInteger begin;
@property (nonatomic, assign) NSInteger count;

@end

@implementation MXSqliteQueryLimitItem

- (NSString *)queryString
{
    NSString *string = [NSString stringWithFormat:@" LIMIT %ld, %ld", (long)self.begin, (long)self.count];
    return string;
}

@end

@interface MXSqliteQuery ()

@property (nonatomic, readonly) NSMutableArray *operatorItems;

@property (nonatomic, readonly) NSMutableArray *sortItems;

@property (nonatomic, strong) MXSqliteQueryLimitItem *limitItem;

@end

@implementation MXSqliteQuery
@synthesize operatorItems = _operatorItems;
@synthesize sortItems = _sortItems;

- (NSMutableArray *)operatorItems
{
    if (!_operatorItems) _operatorItems = [NSMutableArray new];
    return _operatorItems;
}

- (NSMutableArray *)sortItems
{
    if (!_sortItems) _sortItems = [NSMutableArray new];
    return _sortItems;
}

- (MXSqliteQueryOperatorBlock)operate
{
    return ^MXSqliteQuery *(NSString *key, MXSqliteQueryOperator op, id val) {
        MXSqliteQueryOperatorItem *item = [MXSqliteQueryOperatorItem initWithKey:key op:op val:val];
        [self.operatorItems addObject:item];
        return self;
    };
}

- (MXSqliteQueryOperatorBlock)orOperate
{
    return ^MXSqliteQuery *(NSString *key, MXSqliteQueryOperator op, id val) {
        MXSqliteQueryOperatorItem *item = [MXSqliteQueryOperatorItem initWithKey:key op:op val:val];
        item.isOr = YES;
        [self.operatorItems addObject:item];
        return self;
    };
}

- (MXSqliteQuerySortBlock)sort
{
    return ^MXSqliteQuery *(NSString *key, MXSqliteQuerySort sort) {
        MXSqliteQuerySortItem *item = [MXSqliteQuerySortItem new];
        item.key = key;
        item.sort = sort;
        [self.sortItems addObject:item];
        return self;
    };
}

- (MXSqliteQueryLimitBlock)limit
{
    return ^MXSqliteQuery *(NSInteger begin, NSInteger count) {
        MXSqliteQueryLimitItem *item = [MXSqliteQueryLimitItem new];
        item.begin = begin;
        item.count = count;
        self.limitItem = item;
        return self;
    };
}

- (NSString *)queryString
{
    NSString *operatorString = @"";
    for (int i = 0; i < self.operatorItems.count; i++) {
        MXSqliteQueryOperatorItem *item = self.operatorItems[i];
        NSString *flag = i == 0 ? @"WHERE" : item.isOr ? @"OR" : @"AND";
        operatorString = [NSString stringWithFormat:@"%@ %@ %@", operatorString, flag, [item queryString]];
    }
    
    NSString *sortString = @"";
    for (int i = 0; i < self.sortItems.count; i++) {
        MXSqliteQuerySortItem *item = self.sortItems[i];
        NSString *flag = i == 0 ? @"ORDER BY" : @"AND";
        sortString = [NSString stringWithFormat:@" %@ %@", flag, [item queryString]];
    }
    
    NSString *queryString = [operatorString stringByAppendingString:sortString];
    if (self.limitItem) {
        queryString = [queryString stringByAppendingString:[self.limitItem queryString]];
    }
    return queryString;
}

- (void)dealloc
{
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
}

@end
