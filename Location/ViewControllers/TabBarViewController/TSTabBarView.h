//
//  TSTabBarView.h
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSTabBar.h"

typedef enum {
    TSTabShowHideFromLeft = 0,
    TSTabShowHideFromRight,
    TSTabShowHideFromBottom
} TSTabShowHideFrom;

@interface TSTabBarView : UIView

@property (nonatomic, strong) TSTabBar *        tabBar;
@property (nonatomic, strong) UIView *          contentView;
@property (nonatomic, assign) BOOL              isTabBarHidding;
@property (nonatomic) TSTabShowHideFrom         animFrom;

- (void)showTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated;
- (void)hideTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated;

@end
