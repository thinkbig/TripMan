//
//  FeedbackViewController.m
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "FeedbackViewController.h"
#import "UIViewController+InputScroller.h"
#import "CTFeedbackFacade.h"

@interface FeedbackViewController ()

@property (nonatomic, strong) NSString *        sendContact;
@property (nonatomic, strong) NSString *        sendFeedback;

@end

@implementation FeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGSize sz = self.contentScroll.bounds.size;
    self.contentScroll.contentSize = CGSizeMake(sz.width, sz.height+2);
    [self enableAutoScrollerOn:self.contentScroll];
    
    self.title = @"意见反馈";
    self.feedbackField.placeholder = @"您的宝贵意见...";
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
{
    [scrollView endEditing:YES];
}


- (IBAction)sendFeedback:(id)sender
{
    NSString * contact = self.contactField.text;
    NSString * msg = self.feedbackField.text;
    if (0 == contact.length || 0 == msg.length) {
        [self showToast:@"提交内容不能为空" onDismiss:nil];
        return;
    }
    
    if (self.sendContact && self.sendFeedback) {
        if ([self.sendContact isEqualToString:contact] && [self.sendFeedback isEqualToString:msg]) {
            [self showToast:@"反馈已发送，请勿重复提交" onDismiss:nil];
            return;
        }
    }
    
    self.sendContact = contact;
    self.sendFeedback = msg;
    
    CTFeedbackModel * model = [CTFeedbackModel new];
    model.contact = contact;
    model.msg = msg;
    [model updateLocation];
    
    CTFeedbackFacade * facade = [CTFeedbackFacade new];
    [facade request:[model toDictionary] success:^(id result) {
        [self showToast:@"提交成功，感谢您的支持" onDismiss:nil];
    } failure:^(NSError * err) {
        NSString * msg = [GToolUtil msgWithErr:err andDefaultMsg:@"提交失败，请稍后再试"];
        [self showToast:msg onDismiss:nil];
    }];
}

@end
