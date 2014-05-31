#MXSQL

save your object to sqlite easily.

This is a sql data to NSObject mapper base on [FMDB](https://github.com/ccgus/fmdb).

#Usage

	#import "NSObject+MXSQL.h"

	@interface Man : NSObject

	@property (nonatomic, copy) NSString *name;
	@property (nonatomic, assign) int age;
	@property (nonatomic, assign) double money;
	@property (nonatomic, assign) BOOL gfs;
	@property (nonatomic, strong) NSMutableArray *houses;

	@end
	
and than you can new one and save it

	Man *diaosi = [Man new];
	[diaosi save];
	
#License

MXObject is available under the MIT license. See the LICENSE file for more info. 
