//
//  ViewController.m
//
//  Created by longminxiang on 13-10-8.
//  Copyright (c) 2013年 longminxiang. All rights reserved.
//

#import "ViewController.h"
#import "Man.h"
#import "NSObject+MXSQL.h"

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
    NSMutableArray *hhs = [NSMutableArray new];
    for (int i = 100; i < 200; i++) {
        Houses *hh = [Houses new];
        hh.value = i;
        hh.value1 = i;
        hh.name = @"3fd55555fsddd";
        hh.date = [NSDate date];
        
        House *house = [House new];
        house.ownerIndex = i;
        house.name = [NSString stringWithFormat:@"house %d",i];
        house.value = i * 3 + 100;
        hh.house = house;
        
        Man *man = [Man new];
        man.gfs = YES;
        man.age = i;
        man.name = @"qqq";
        man.money = 500 + i;
        hh.man = man;
        
        [hhs addObject:hh];
    }
    [Houses save:hhs withoutFields:nil completion:^{
        [Houses query:^(NSArray *objects) {
            for (Houses *ho in objects) {
                NSLog(@"%@,%d",ho.name,ho.value1);
            }
        } field:nil conditions:nil];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
