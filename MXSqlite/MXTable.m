//
//  MXTable.m
//
//  Created by longminxiang on 14-1-27.
//  Copyright (c) 2014年 longminxiang. All rights reserved.
//

#import "MXTable.h"

#pragma mark === MXTable ===

@implementation MXTable
@synthesize idxField = _idxField;

- (instancetype)clone
{
    if (!self) return nil;
    MXTable *table = [MXTable new];
    table.name = self.name;
    table.keyField = self.keyField;
    NSArray *fields;
    if (self.fields) fields = [NSArray arrayWithArray:self.fields];
    table.fields = fields;
    return table;
}

- (instancetype)cloneWithExcludeFields:(NSArray *)fields
{
    if (!self) return nil;
    MXTable *table = [MXTable new];
    table.name = self.name;
    table.keyField = self.keyField;

    if (self.fields) {
        NSMutableArray *newFields = [NSMutableArray arrayWithArray:self.fields];
        for (NSString *fieldName in fields) {
            for (MXField *field in self.fields) {
                if ([fieldName isEqualToString:field.name]) {
                    [newFields removeObject:field];
                    break;
                }
            }
        }
        table.fields = newFields;
    }
    return table;
}

- (MXField *)idxField
{
    if (_idxField) return _idxField;
    for (MXField *field in self.fields) {
        if ([field isIdxField]) {
            _idxField = field;
            break;
        }
    }
    return _idxField;
}

- (BOOL)isKeyFieldEmpty
{
    NSString *name = self.keyField.name;
    return !name || [name isEqualToString:@""];
}

@end


