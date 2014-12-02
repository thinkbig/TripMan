//
//  CoorViewX.m
//  MPPlotExample
//
//  Created by taq on 12/1/14.
//  Copyright (c) 2014 mpow. All rights reserved.
//

#import "CoorViewX.h"

@implementation CoorViewX

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)setCoorStrArray:(NSArray *)coorStrArray
{
    _coorStrArray = coorStrArray;
    NSArray * subViews = self.subviews;
    for (UIView * oldView in subViews) {
        [oldView removeFromSuperview];
    }
    
    for (NSString * str in coorStrArray) {
        UILabel * newLabel = self.geneLabelBlock(str);
        newLabel.alpha = 0;
        [self addSubview:newLabel];
    }
}

- (GeneCoorLabelBlock)geneLabelBlock
{
    if (nil == _geneLabelBlock) {
        _geneLabelBlock = ^(NSString * str) {
            UILabel * label = [UILabel new];
            label.text = str;
            [label sizeToFit];
            return label;
        };
    }
    return _geneLabelBlock;
}


- (void) willLayoutIndex:(NSUInteger)idx
{
    NSArray * subViews = self.subviews;
    if (idx < subViews.count) {
        UILabel * label = subViews[idx];
        label.alpha = 0;
    }
}

- (void) didLayoutIndex:(NSUInteger)idx ofTopPoint:(CGPoint)point
{
    NSArray * subViews = self.subviews;
    if (idx < subViews.count) {
        UILabel * label = subViews[idx];
        label.center = CGPointMake(point.x, self.bounds.size.height*1.3f);
        
        [UIView animateWithDuration:0.3 animations:^{
            label.center = CGPointMake(point.x, self.bounds.size.height*0.4f);
            label.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                label.center = CGPointMake(point.x, self.bounds.size.height*0.5f);
            }];
        }];
    }
}

@end
