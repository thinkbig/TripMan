//
//  AboutViewController.m
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "AboutViewController.h"
#import "STAlertView.h"

@interface AboutViewController ()

@property (nonatomic, strong) STAlertView *     stAlert;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"关于我们";
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSecret)];
    tapGesture.numberOfTapsRequired = 5;
    tapGesture.numberOfTouchesRequired = 2;
#if (TARGET_IPHONE_SIMULATOR)
    tapGesture.numberOfTouchesRequired = 1;
#endif
    [self.navigationController.navigationBar addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tapSecret
{
    self.stAlert = [[[STAlertView alloc] initWithTitle:@"邀请码"
                               message:@"请输入邀请码"
                         textFieldHint:@"输入邀请码"
                        textFieldValue:nil
                     cancelButtonTitle:@"取消"
                      otherButtonTitle:@"确定"
                     cancelButtonBlock:nil otherButtonBlock:^(NSString * result){
                         if ([result isEqualToString:@"321"]) {
                             [self presentViewController:InstFirstVC(@"Debug") animated:YES completion:nil];
                         } else {
                             [self showToast:@"邀请码错误" onDismiss:nil];
                         }
                     }] show];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
