//
//  MXSqliteRecord.m
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import "MXSqliteRecord.h"

NSString *const MXSqliteDefaultPkFieldName = @"mxsql_id";

@implementation MXSqliteField

- (instancetype)clone
{
    MXSqliteField *field = [MXSqliteField new];
    field.name = self.name;
    field.type = self.type;
    return field;
}

- (void)setType:(MXSqliteFieldType)type
{
    _type = type;
    switch (type) {
        case MXSqliteStringField: _typeString = @"string"; break;
        case MXSqliteIntegerField: _typeString = @"integer"; break;
        case MXSqliteBoolField: _typeString = @"boolean"; break;
        case MXSqliteFloatField: _typeString = @"float"; break;
        case MXSqliteDateField: _typeString = @"date"; break;
        case MXSqliteDataField: _typeString = @"blob"; break;
        default:break;
    }
}

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"%@: %@: %@", self.name, self.typeString, self.value];
    return des;
}

@end

@implementation MXSqliteField (DefaultPkField)

+ (MXSqliteField *)defaultPkField
{
    MXSqliteField *field = [MXSqliteField new];
    field.name = MXSqliteDefaultPkFieldName;
    field.type = MXSqliteIntegerField;
    return field;
}

- (BOOL)isDefaultPkField
{
    return [self.name isEqualToString:MXSqliteDefaultPkFieldName];
}

@end

@implementation MXSqliteRecord

- (instancetype)clone
{
    MXSqliteRecord *record = [MXSqliteRecord new];
    record.name = self.name;
    record.pkField = [self.pkField clone];
    NSMutableDictionary *fields = [NSMutableDictionary new];
    [self.fields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, MXSqliteField *field, BOOL * _Nonnull stop) {
        fields[key] = [field clone];
    }];
    record.fields = fields;
    return record;
}

- (BOOL)checkPkField:(MXSqliteField *)field
{
    return [field.name isEqualToString:self.pkField.name];
}

@end
