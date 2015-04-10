//
//  OpenGpsViewController.m
//  TripMan
//
//  Created by taq on 4/5/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "OpenGpsViewController.h"

@interface OpenGpsViewController ()

@end

@implementation OpenGpsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.ios7HintView.hidden = YES;
    } else {
        UIImageView *ios7GuideImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"guide_opengps_ios7"]];
        [self.ios7HintView addSubview:ios7GuideImage];
        self.ios7HintView.contentSize = ios7GuideImage.bounds.size;
    }
    
    NSString * hintStr = @"车图需要使用您的 位置 来记录行驶轨迹和优化您行程，并且需要 运动记录 来优化电量";
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:hintStr];
    
    NSRange range1 = [hintStr rangeOfString:@" 位置 "];
    NSRange range2 = [hintStr rangeOfString:@" 运动记录 "];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range1];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range2];

    self.hintLabel.attributedText = attrStr;
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

- (IBAction)close:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openSetting:(id)sender {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end
