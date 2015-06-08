//
//  MainTabViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "MainTabViewController.h"
#import "TSTabBarItem.h"
#import "NoGpsHintView.h"
#import "OpenGpsViewController.h"

@interface MainTabViewController ()

@end

@implementation MainTabViewController

- (void)loadView
{
    UIViewController* homeVC = InstFirstVC(@"CarHome");
    UIViewController* tripVC = InstFirstVC(@"CarTrip");;
    UIViewController* assistorVC = InstFirstVC(@"CarAssistor");;
    //UIViewController* healthVC = InstFirstVC(@"CarHealth");
    UIViewController* settingVC = InstFirstVC(@"CarSetting");
    
    NSArray * itemIcons = @[@"tab01", @"tab02", @"tab03", @"tab05"];
    NSArray * highlightIcons = @[@"tab01_active", @"tab02_active", @"tab03_active", @"tab05_active"];
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
    
    [self setViewControllers:@[homeVC, tripVC, assistorVC, settingVC] withTabBarItemModels:itemModels];
    
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.tabBar setTabShadowImage:[UIImage imageNamed:@"shadowtab"]];
    self.tabBar.backgroundImageView.image = [UIImage imageNamed:@"tabbar"];
    [self setSelectedIndex:0 animed:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterForeground) name:@"kLocationAuthrizeStatChange" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self applicationEnterForeground];
}

- (void)applicationEnterForeground
{
    // show hint view
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusAuthorizedAlways != authorizationStatus) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"NoGpsHintView" owner:self options:nil];
        NoGpsHintView * hintView = (NoGpsHintView*)[nibs objectAtIndex:0];
        [hintView.howToBtn addTarget:self action:@selector(showHowToOpenGps) forControlEvents:UIControlEventTouchUpInside];
        [self showHintView:hintView];
    } else {
        [self showHintView:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showHowToOpenGps
{
    OpenGpsViewController * openGpsVC = InstFirstVC(@"OpenGps");
    [self presentViewController:openGpsVC animated:YES completion:nil];
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
