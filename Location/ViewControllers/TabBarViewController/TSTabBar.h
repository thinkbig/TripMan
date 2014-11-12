//
//  TSTabBar.h
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TSTabBarDelegate <NSObject>

@optional
- (void)tabBar:(id)tabBar willSelectItemAtIndex:(NSUInteger)index currentIndex:(NSUInteger)currentIndex;
- (void)tabBar:(id)tabBar didSelectItemAtIndex:(NSUInteger)index prviousIndex:(NSUInteger)prviousIndex;
- (void)tabBar:(id)tabBar clickItemAtIndex:(NSUInteger)index currentIndex:(NSUInteger)currentIndex;
@end

@interface TSTabBar : UIView

@property (nonatomic, assign) id<TSTabBarDelegate>  delegate;
@property (nonatomic) NSUInteger                    selectedIndex;
@property (nonatomic, strong) UIImageView *         backgroundImageView;
@property (nonatomic, strong) UIImageView *         selectedImageView;
@property (nonatomic, strong) UIImageView *         devideLineImageView;
@property (nonatomic, strong) NSArray *             itemModels;

- (void)setSelectedIndex:(NSUInteger)selectedIndex animed:(BOOL)animed;
- (void)setBadge:(NSString*)badgeStr forIndex:(NSUInteger)idx;

@end
