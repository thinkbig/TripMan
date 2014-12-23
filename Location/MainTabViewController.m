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
    
    NSArray * itemIcons = @[@"tab01", @"tab02", @"tab03", @"tab04", @"tab05"];
    NSArray * highlightIcons = @[@"tab01_active", @"tab02_active", @"tab03_active", @"tab04_active", @"tab05_active"];
    //NSArray * itemTitles = @[@"首页", @"旅程", @"问路", @"健康", @"设置"];
    
    NSMutableArray * itemModels = [NSMutableArray array];
    [itemIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        TSTabBarItemModel * model = [TSTabBarItemModel new];
        model.itemIndex = idx;
        model.itemImage = [UIImage imageNamed:obj];
        model.itemSelectedImage = [UIImage imageNamed:highlightIcons[idx]];
        //model.itemTitle = itemTitles[idx];
        [itemModels addObject:model];
    }];
    
    [self setViewControllers:@[homeVC, tripVC, assistorVC, healthVC, settingVC] withTabBarItemModels:itemModels];
    
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tabBar.devideLineImageView.image = nil;
    self.tabBar.backgroundImageView.image = [UIImage imageNamed:@"tabbar"];
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
