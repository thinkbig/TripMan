//
//  AboutViewController.m
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "AboutViewController.h"
#import "STAlertView.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutViewController () <TTTAttributedLabelDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) STAlertView *     stAlert;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"关于我们";
    
    NSString * vstring = [NSString stringWithFormat:@"当前版本：version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    self.versionLabel.text = vstring;
    
    NSRange range = [self.emailLabel.text rangeOfString:@"developer@carmap.me"];
    [self.emailLabel addLinkToURL:[NSURL URLWithString:@"mailto://developer@carmap.me"] withRange:range]; // Embedding a custom link in a substring
    self.emailLabel.delegate = self;
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSecret)];
    if ([GToolUtil isEnableDebug]) {
        tapGesture.numberOfTapsRequired = 2;
        tapGesture.numberOfTouchesRequired = 1;
    } else {
        tapGesture.numberOfTapsRequired = 5;
        tapGesture.numberOfTouchesRequired = 2;
#if (TARGET_IPHONE_SIMULATOR)
        tapGesture.numberOfTouchesRequired = 1;
#endif
    }
    [self.navigationController.navigationBar addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if (![MFMailComposeViewController canSendMail]) {
        [self showToast:@"无法发送邮件，请确认正确设置了手机的邮件账号" onDismiss:nil];
        return;
    }
    MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
    mailCompose.mailComposeDelegate = self;
    NSArray *toAddress = [NSArray arrayWithObject:@"developer@carmap.me"];
    
    [mailCompose setToRecipients:toAddress];

    [self.navigationController presentViewController:mailCompose animated:YES completion:nil];
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
                         if ([result isEqualToString:@"CHEtu.123@321"]) {
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

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *msg = @"邮件发送";
    switch (result)
    {
        case MFMailComposeResultCancelled:
            msg = @"邮件发送取消";
            break;
        case MFMailComposeResultSaved:
            msg = @"邮件保存成功";
            break;
        case MFMailComposeResultSent:
            msg = @"邮件发送成功";
            break;
        case MFMailComposeResultFailed:
            msg = @"邮件发送失败";
            break;
        default:
            break;
    }
    [self showToast:msg onDismiss:nil];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
