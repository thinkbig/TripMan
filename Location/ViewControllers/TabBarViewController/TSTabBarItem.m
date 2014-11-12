//
//  TSTabBarItem.m
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSTabBarItem.h"
#import "TSTabBarConfig.h"

@implementation TSTabBarItemModel

@end


@implementation TSTabBarItem

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.adjustsImageWhenHighlighted = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return self;
}

- (void)setItemModel:(TSTabBarItemModel *)itemModel
{
    _itemModel = itemModel;
    [self setImage:itemModel.itemImage forState:UIControlStateNormal];
    [self setImage:itemModel.itemImage forState:UIControlStateDisabled];
    [self setImage:itemModel.itemSelectedImage forState:UIControlStateHighlighted];
    [self setImage:itemModel.itemSelectedImage forState:UIControlStateSelected];
}

- (void)setItemBadge:(NSString*)str
{
    if (str.length > 0) {
        self.badgeValueView.hidden = NO;
        [self.badgeValueView autoBadgeSizeWithString:str];
        self.badgeValueView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        [UIView animateWithDuration:0.3 animations:^{
            self.badgeValueView.transform = CGAffineTransformIdentity;
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.badgeValueView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            self.badgeValueView.transform = CGAffineTransformIdentity;
            self.badgeValueView.hidden = YES;
        }];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        [self setImage:_itemModel.itemSelectedImage forState:UIControlStateNormal];
    } else {
        [self setImage:_itemModel.itemImage forState:UIControlStateNormal];
    }
}

- (CustomBadge *)badgeValueView
{
    if (_badgeValueView == nil) {
        CGFloat x = itemSize - badgeSize + 10;
        CGFloat y = -5;
        _badgeValueView = [CustomBadge customBadgeWithString:@""
                                         withStringColor:[UIColor whiteColor]
                                          withInsetColor:[UIColor redColor]
                                          withBadgeFrame:YES
                                     withBadgeFrameColor:[UIColor colorWithWhite:1.0f alpha:0.5]
                                               withScale:1.0
                                             withShining:NO];
        _badgeValueView.frame = CGRectMake(x, y, badgeSize, badgeSize);
        [self addSubview:_badgeValueView];
        
    }
    return  _badgeValueView;
}


@end
