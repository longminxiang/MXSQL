//
//  MXSqliteRecord.h
//  Pods
//
//  Created by eric on 16/8/8.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MXSqliteFieldType)
{
    MXSqliteNullField = 0,
    MXSqliteStringField,
    MXSqliteIntegerField,
    MXSqliteBoolField,
    MXSqliteFloatField,
    MXSqliteDateField,
    MXSqliteDataField,
};

FOUNDATION_EXPORT NSString *const MXSqliteDefaultPkFieldName;

@interface MXSqliteField : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) MXSqliteFieldType type;

@property (nonatomic, strong) id value;

@property (nonatomic, readonly) NSString *typeString;

- (instancetype)clone;

@end

@interface MXSqliteField (DefaultPkField)

+ (MXSqliteField *)defaultPkField;

- (BOOL)isDefaultPkField;

@end

@interface MXSqliteRecord : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) MXSqliteField *pkField;

@property (nonatomic, strong) NSMutableDictionary *fields;

- (instancetype)clone;

@end
