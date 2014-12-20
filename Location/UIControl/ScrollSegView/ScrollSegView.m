//
//  ScrollSegView.m
//  TripMan
//
//  Created by taq on 12/18/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "ScrollSegView.h"

@interface ScrollSegView ()

@property (nonatomic, strong) NSMutableArray *      segViews;

@end

@implementation ScrollSegView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UIColor *)normalTextColor
{
    if (nil == _normalTextColor) {
        _normalTextColor = UIColorFromRGB(0xbbbbbb);
    }
    return _normalTextColor;
}

- (UIColor *)hightLightTextColor
{
    if (nil == _hightLightTextColor) {
        _hightLightTextColor = [UIColor whiteColor];
    }
    return _hightLightTextColor;
}

- (void)setSegStrings:(NSArray *)segStrings
{
    _segStrings = segStrings;
    
    if (nil == self.segViews) {
        self.segViews = [NSMutableArray arrayWithCapacity:segStrings.count];
    }
    for (UIView * oldView in self.segViews) {
        [oldView removeFromSuperview];
    }
    [self.segViews removeAllObjects];
    
    CGFloat height = self.bounds.size.height;
    [segStrings enumerateObjectsUsingBlock:^(NSString * str, NSUInteger idx, BOOL *stop) {
        UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 80, height);
        [btn setTitleColor:self.normalTextColor forState:UIControlStateNormal];
        [btn setTitleColor:self.hightLightTextColor forState:UIControlStateHighlighted];
        [btn setTitleColor:self.hightLightTextColor forState:UIControlStateSelected];
        btn.titleLabel.font = [UIFont systemFontOfSize:18];
        [btn setTitle:str forState:UIControlStateNormal];
        [btn sizeToFit];
        btn.tag = idx;
        [btn addTarget:self action:@selector(selItem:) forControlEvents:UIControlEventTouchUpInside];
        [self.segViews addObject:btn];
        [self addSubview:btn];
    }];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    __block CGFloat xPos = 0;
    [self.segViews enumerateObjectsUsingBlock:^(UIButton * obj, NSUInteger idx, BOOL *stop) {
        CGRect oldRc = obj.frame;
        oldRc.origin.x = xPos;
        obj.frame = oldRc;
        xPos = CGRectGetMaxX(oldRc);
        obj.selected = (idx == _selIdx);
    }];
    
    self.contentSize = CGSizeMake(xPos, self.bounds.size.height);
}

- (void)selItem:(UIButton*)btn
{
    self.selIdx = btn.tag;
}

- (void)setSelIdx:(NSUInteger)selIdx
{
    if (_selIdx != selIdx) {
        _selIdx = selIdx;
        [self.segViews enumerateObjectsUsingBlock:^(UIButton * obj, NSUInteger idx, BOOL *stop) {
            obj.selected = (idx == selIdx);
        }];
        if (self.selBlock) {
            self.selBlock(selIdx);
        }
    }
}

@end
