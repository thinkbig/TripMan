//
//  TSTabBarViewController.h
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSTabBarView.h"

@interface TSTabBarViewController : UIViewController <TSTabBarDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSArray*                          viewControllers;

@property (nonatomic, readonly) UIViewController*               selectedViewController;
@property (nonatomic) NSUInteger                                selectedIndex;

@property (nonatomic, strong) TSTabBar*                         tabBar;
@property (nonatomic, weak) id<UITabBarControllerDelegate>      delegate;

- (void)setViewControllers:(NSArray *)viewControllers withTabBarItemModels:(NSArray*)models;
- (void)setSelectedIndex:(NSUInteger)selectedIndex animed:(BOOL)animed;
- (void)setBadge:(NSString*)badgeStr forIndex:(NSUInteger)idx;

- (void)showTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated;
- (void)hideTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated;

@end
