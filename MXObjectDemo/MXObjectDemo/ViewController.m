//
//  ViewController.m
//
//  Created by longminxiang on 13-10-8.
//  Copyright (c) 2013年 longminxiang. All rights reserved.
//

#import "ViewController.h"
#import "Man.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(60, 80, 200, 44)];
    [button setTitle:@"touch see see" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonTouched:(id)sender
{
    Man *diaosi = [Man new];
    diaosi.name = @"a san";
    diaosi.age = 30;
    diaosi.gfs = NO;
    diaosi.brithday = [NSDate date];
    [diaosi save];

    Man *ds = [Man new];
    ds.iindex = diaosi.iindex;
    [ds freshWithIndex];
    
    NSLog(@"%@ diaosi %lld born",ds.brithday,ds.iindex);
    ds.age = 31;
    ds.gfs = YES;
    [ds save];


    Man *gaofusuai = [Man new];
    gaofusuai.name = @"wlh";
    gaofusuai.money = 1000000000;
    gaofusuai.age = 28;
    gaofusuai.gfs = YES;
    [gaofusuai save];
    NSLog(@"gaofusuai %lld born",gaofusuai.iindex);
    
    gaofusuai.houses = [NSMutableArray new];
    for (int i = 0; i < 1000; i++) {
        House *house = [House new];
        house.ownerIndex = gaofusuai.iindex;
        house.name = [NSString stringWithFormat:@"house %d",i];
        house.value = 5000000;
        [gaofusuai.houses addObject:house];
    }
    [Houses save:gaofusuai.houses completion:^{
        [House query:^(NSArray *objects) {
            for (int i = 0; i < objects.count; i++) {
                House *hs = (House *)objects[i];
                NSLog(@"gaofusuai %lld bought house %lld",gaofusuai.iindex,hs.iindex);
            }
        } conditions:[MXCondition whereKey:@"ownerIndex" equalTo:[NSNumber numberWithInt:gaofusuai.iindex]], nil];
    }];

    
    [Man queryAll:^(NSArray *objects) {
        for (Man *man in objects) {
            NSLog(@"man %lld %@",man.iindex,man.gfs ? @"is gaofusuai" : @"is diaosi");
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
