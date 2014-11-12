//
//  TSTabBarViewController.m
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSTabBarViewController.h"
#import "TSTabBarView.h"
#import "TSTabBarConfig.h"

@interface TSTabBarViewController ()

@property (nonatomic, strong) NSArray *             itemModels;

@property (nonatomic, strong) NSArray *             prevViewControllers;
@property (nonatomic, strong) TSTabBarView *        tabBarView;

@end

@implementation TSTabBarViewController

- (void)internalInit {
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    // Creating and adding the tab bar view
    self.tabBarView = [[TSTabBarView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    _tabBarView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.view = _tabBarView;
    
    // Creating and adding the tab bar
    CGRect tabBarRect = CGRectMake(0.0, CGRectGetHeight(self.view.bounds) - kDefaultTabBarHeight, CGRectGetWidth(self.view.frame), kDefaultTabBarHeight);
    self.tabBar = [[TSTabBar alloc] initWithFrame:tabBarRect];
    self.tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.tabBar.delegate = self;
    self.tabBar.itemModels = _itemModels;

    _tabBarView.tabBar = _tabBar;
    UIViewController * selVC = self.selectedViewController;
    _tabBarView.contentView = selVC.view;
    [[self navigationItem] setTitle:[selVC title]];
}

- (UIViewController*)selectedViewController {
    return [self.viewControllers objectAtIndex:_selectedIndex];
}

- (void) setViewControllers:(NSArray *)viewControllers withTabBarItemModels:(NSArray*)models
{
    if (viewControllers.count == models.count && models.count > 0) {
        self.viewControllers = viewControllers;
        self.itemModels = models;
        self.tabBar.itemModels = _itemModels;
        [viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self addChildViewController:obj];
            if ([[obj class] isSubclassOfClass:[UINavigationController class]])
                ((UINavigationController *)obj).delegate = self;
        }];
    } else {
        NSLog(@"viewcontrollers should be the same count with models");
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex animed:(BOOL)animed
{
    [self.tabBar setSelectedIndex:selectedIndex animed:animed];
}

- (void)setBadge:(NSString*)badgeStr forIndex:(NSUInteger)idx
{
    [self.tabBar setBadge:badgeStr forIndex:idx];
}

- (void)showTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated
{
    [self.tabBarView showTabBar:showHideFrom animated:animated];
}

- (void)hideTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated
{
    [self.tabBarView hideTabBar:showHideFrom animated:animated];
}


#pragma mark - TSTabBarDelegate

- (void)tabBar:(id)tabBar willSelectItemAtIndex:(NSUInteger)index currentIndex:(NSUInteger)currentIndex {
    self.selectedIndex = index;
    if (nil == _tabBarView.contentView || currentIndex != index) {
        [self.tabBarView setContentView:self.selectedViewController.view];
    }
}

- (void)tabBar:(id)tabBar clickItemAtIndex:(NSUInteger)index currentIndex:(NSUInteger)currentIndex{
//    if (index == currentIndex) {
//        UIViewController * vc = self.viewControllers[index];
//        if ([vc isKindOfClass:[UINavigationController class]]) {
//            UINavigationController * nc = (UINavigationController*)vc;
//            if (nc.viewControllers && nc.viewControllers.count>0) {
//                vc = nc.viewControllers[0];
//            }
//            else{
//                vc = nil;
//            }
//        }
//        if (vc && [vc conformsToProtocol:@protocol (UIViewControllerCommonAction) ]
//            && [vc respondsToSelector:@selector(viewControllerNeedUpdateData)]) {
//            id<UIViewControllerCommonAction> commonAction = (id<UIViewControllerCommonAction> ) vc;
//            [commonAction viewControllerNeedUpdateData];
//        }
//    }
}


#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.prevViewControllers)
        self.prevViewControllers = [navigationController viewControllers];
    
    
    // We detect is the view as been push or popped
    BOOL pushed;
    
    if ([_prevViewControllers count] <= [[navigationController viewControllers] count])
        pushed = YES;
    else
        pushed = NO;
    
    // Logic to know when to show or hide the tab bar
    BOOL isPreviousHidden, isNextHidden;
    
    isPreviousHidden = [[_prevViewControllers lastObject] hidesBottomBarWhenPushed];
    isNextHidden = [viewController hidesBottomBarWhenPushed];
    
    _prevViewControllers = [navigationController viewControllers];
    
    if (!isPreviousHidden && !isNextHidden)
        return;
    
    else if (!isPreviousHidden && isNextHidden)
        [self hideTabBar:(pushed ? TSTabShowHideFromRight : TSTabShowHideFromLeft) animated:animated];
    
    else if (isPreviousHidden && !isNextHidden)
        [self showTabBar:(pushed ? TSTabShowHideFromRight : TSTabShowHideFromLeft) animated:animated];
    
    else if (isPreviousHidden && isNextHidden)
        return;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [_tabBarView setNeedsLayout];
}

@end
