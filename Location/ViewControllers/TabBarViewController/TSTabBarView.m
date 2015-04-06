//
//  TSTabBarView.m
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSTabBarView.h"
#import "TSTabBarConfig.h"

@implementation TSTabBarView

#pragma mark - Setters

- (void)setTabBar:(TSTabBar *)tabBar
{
    if (_tabBar != tabBar)
    {
        [_tabBar removeFromSuperview];
        _tabBar = tabBar;
        [self addSubview:tabBar];
    }
}


- (void)setContentView:(UIView *)contentView
{
    if (_contentView != contentView)
    {
        [_contentView removeFromSuperview];
        _contentView = contentView;
        _contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.tabBar.frame.origin.y);
        [self addSubview:_contentView];
        [self sendSubviewToBack:_contentView];
        [_contentView setNeedsDisplay];
        [self setNeedsLayout];
    }
}

- (void)setHintView:(UIView *)hintView
{
    if (_hintView != hintView)
    {
        [_hintView removeFromSuperview];
        _hintView = hintView;
        
        if (_hintView) {
            CGRect hintRect = hintView.frame;
            _hintView.center = CGPointMake(self.bounds.size.width/2.0, self.tabBar.frame.origin.y-hintRect.size.height/2.0);
            [self addSubview:_hintView];
        }
        [self setNeedsLayout];
    }
}

- (void)showTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated
{
    BOOL shouldAnimContent = (TSTabShowHideFromBottom == showHideFrom);
    CGFloat animDuring = (TSTabShowHideFromBottom == showHideFrom) ? kPushAnimationDuration*1.5 : kPushAnimationDuration;
    
    _isTabBarHidding = NO;
    _animFrom = showHideFrom;
    [UIView animateWithDuration:((animated) ? animDuring : 0) animations:^{
        if (shouldAnimContent) {
            [self layoutSubviews];
        } else {
            [self layoutTabBar];
        }
    } completion:^(BOOL finished) {
        [self layoutSubviews];
    }];
}

- (void)hideTabBar:(TSTabShowHideFrom)showHideFrom animated:(BOOL)animated
{
    BOOL shouldAnimContent = (TSTabShowHideFromBottom == showHideFrom);
    CGFloat animDuring = (TSTabShowHideFromBottom == showHideFrom) ? kPushAnimationDuration*1.5 : kPushAnimationDuration;
    
    _isTabBarHidding = YES;
    _animFrom = showHideFrom;
    if (!shouldAnimContent) {
        [self layoutContent];
    }
    [UIView animateWithDuration:((animated) ? animDuring : 0) animations:^{
        [self layoutSubviews];
    }];
}

- (void)layoutTabBar
{
    CGFloat directionVector = 0.0;
    switch (_animFrom) {
        case TSTabShowHideFromLeft:
            directionVector = -1.0;
            break;
        case TSTabShowHideFromRight:
            directionVector = 1.0;
            break;
        default:
            break;
    }
    _tabBar.frame = (CGRect) {
        .origin.x = self.bounds.origin.x - (_isTabBarHidding ? (directionVector*CGRectGetWidth(self.bounds)) : 0),
        .origin.y = CGRectGetHeight(self.bounds) - ((_isTabBarHidding && _animFrom == TSTabShowHideFromBottom) ? 0 : CGRectGetHeight(_tabBar.bounds)),
        .size = _tabBar.frame.size
    };
}

- (void)layoutContent
{
    _contentView.frame = (CGRect) {
        .origin.x = 0,
        .origin.y = 0,
        .size.width = CGRectGetWidth(self.bounds),
        .size.height = CGRectGetHeight(self.bounds) - ((!_isTabBarHidding) ? CGRectGetHeight(_tabBar.bounds) : 0)
    };
    [_contentView setNeedsLayout];
}

- (void)layoutHint
{
    _hintView.frame = (CGRect) {
        .origin.x = 0,
        .origin.y = self.tabBar.frame.origin.y-40,
        .size.width = CGRectGetWidth(self.bounds),
        .size.height = 40
    };
}

#pragma mark - Layout & Drawing

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self layoutTabBar];
    [self layoutContent];
    [self layoutHint];
}




@end
