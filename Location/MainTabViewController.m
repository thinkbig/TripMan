//
//  MainTabViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "MainTabViewController.h"
#import "TSTabBarItem.h"

@interface MainTabViewController ()

@end

@implementation MainTabViewController

- (void)loadView
{
    UIViewController* homeVC = InstFirstVC(@"CarHome");
    UIViewController* tripVC = InstFirstVC(@"CarTrip");;
    UIViewController* assistorVC = InstFirstVC(@"CarAssistor");;
    UIViewController* healthVC = InstFirstVC(@"CarHealth");
    UIViewController* settingVC = InstFirstVC(@"CarSetting");
    
    NSArray * itemIcons = @[@"navicon_activity_normal", @"navicon_connection_normal", @"navicon_find_normal", @"navicon_me_normal", @"navicon_me_normal"];
    NSArray * highlightIcons = @[@"navicon_activity_active", @"navicon_connection_active", @"navicon_find_active", @"navicon_me_active", @"navicon_me_active"];
    NSArray * itemTitles = @[@"首页", @"旅程", @"问路", @"健康", @"设置"];
    
    NSMutableArray * itemModels = [NSMutableArray array];
    [itemIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        TSTabBarItemModel * model = [TSTabBarItemModel new];
        model.itemIndex = idx;
        model.itemImage = [UIImage imageNamed:obj];
        model.itemSelectedImage = [UIImage imageNamed:highlightIcons[idx]];
        model.itemTitle = itemTitles[idx];
        [itemModels addObject:model];
    }];
    
    [self setViewControllers:@[homeVC, tripVC, assistorVC, healthVC, settingVC] withTabBarItemModels:itemModels];
    
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setSelectedIndex:0 animed:YES];
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
