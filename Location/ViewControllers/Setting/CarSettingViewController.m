//
//  CarSettingViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarSettingViewController.h"

@interface CarSettingViewController ()

@end

@implementation CarSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)showDebug:(id)sender {
    [self.navigationController pushViewController:InstVC(@"Debug", @"LogDisplayList") animated:YES];
}

- (IBAction)reInstall:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://fir.im/y764"]];
}

@end
