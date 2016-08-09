//
//  ViewController.m
//  MXSqliteDemo
//
//  Created by eric on 15/7/10.
//  Copyright (c) 2015年 eric. All rights reserved.
//

#import "ViewController.h"
#import "Man.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(60, 80, 200, 44)];
    [button setTitle:@"touch see see" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    NSLog(@"%@", [MXSqlite objInstance].dbPath);
}

- (void)buttonTouched:(id)sender
{
    Man *diaosi = [Man new];
    diaosi.name = @"sandy";
    diaosi.gfs = NO;
    diaosi.brithday = [NSDate date];
    diaosi.nick = @"ssss";
    diaosi.nick2 = @"ssss";
    diaosi.nick1 = @"ssss";
    [diaosi mxsql_save];
//        NSMutableArray *array = [NSMutableArray new];
//        for (int i = 0; i < 100; i++) {
//            Man *diaosi = [Man new];
//            diaosi.name = [NSString stringWithFormat:@"san%d", i % 15];
//            diaosi.age = i;
//            diaosi.gfs = NO;
//            diaosi.brithday = [NSDate date];
//            diaosi.xxx = i+2;
//            diaosi.nick = @"ssss";
//            diaosi.nick2 = @"ssss";
//            diaosi.nick1 = @"ssss";
//            [array addObject:diaosi];
//        }
//        [Man save:array completion:^{
//            for (Man *man in array) {
//                NSLog(@"%@", [man fields]);
//            }
//        }];
    
    //    [Man queryAll:^(NSArray *objects) {
    //        for (Man *man in objects) {
    //            NSLog(@"%@", [man fields]);
    //        }
    //    }];
//    Man *m = [Man new];
//    m.idx = 2;
//    [m freshWithIdx];
//    NSLog(@"%@", [m fields]);
//    m.name = @"san10";
//    [m freshWithKeyField];
//    NSLog(@"%@", [m fields]);
    
    [Man query:^(MXSqliteQuery *query) {
        query.op(@"xxx", MXSqliteQueryOperatorEqual, @(5));
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
