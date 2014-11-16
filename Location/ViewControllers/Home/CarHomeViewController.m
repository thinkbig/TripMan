//
//  CarHomeViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarHomeViewController.h"

@interface CarHomeViewController ()

@end

@implementation CarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"1234567890-1234567890-1234567890"];
    [str addAttribute:NSBackgroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,7)];
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor yellowColor] range:NSMakeRange(7,12)];
    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0] range:NSMakeRange(12, 20)];
    self.suggestDistFrom.attributedText = str;
                                      
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

@end
