#MXSQL

save your object to sqlite easily.

This is a sql data to NSObject mapper base on [FMDB](https://github.com/ccgus/fmdb).

#Usage

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

and than you can new one and save it

	Man *diaosi = [Man new];
	[diaosi save];

#License

MXSQL is available under the MIT license. See the LICENSE file for more info. 
