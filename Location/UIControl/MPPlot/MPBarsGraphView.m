//
//  MPBarsGraphView.m
//  MPPlot
//
//  Created by Alex Manzella on 22/05/14.
//  Copyright (c) 2014 mpow. All rights reserved.
//

#import "MPBarsGraphView.h"

@implementation MPBarsGraphView

- (void) internalInit
{
    self.backgroundColor = [UIColor clearColor];
    currentTag = -1;
    self.topCornerRadius = -1;
    self.bounceHeight = 20;
    self.minHeight = 10;
    self.upSideDown = NO;
    self.showBottomLine = YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.values.count && !self.waitToUpdate) {
        
        for (UIView *subview in self.subviews) {
            [subview removeFromSuperview];
        }
        
        [self addBarsAnimated:shouldAnimate];
        [self.graphColor setStroke];

        if (self.showBottomLine) {
            UIBezierPath *line = [UIBezierPath bezierPath];
            [line moveToPoint:CGPointMake(PADDING, self.height)];
            [line addLineToPoint:CGPointMake(self.width-PADDING, self.height)];
            [line setLineWidth:1];
            [line stroke];
        }
    }
}

- (void)addBarsAnimated:(BOOL)animated
{
    for (UIButton* button in buttons) {
        [button removeFromSuperview];
    }
    
    buttons=[[NSMutableArray alloc] init];
    //animated = NO;
    if (animated) {
        self.layer.masksToBounds=YES;
    }
    
    CGFloat bounceHeight = self.bounceHeight;
    CGFloat minHeight = self.minHeight;
    CGFloat barWidth = self.width/(points.count*2+1);
    CGFloat radius = barWidth*(self.topCornerRadius >=0 ? self.topCornerRadius : 0.3);
    
    for (NSInteger i=0; i<points.count; i++) {
        
        CGFloat height = [[points objectAtIndex:i] floatValue]*(self.height-PADDING-minHeight)+minHeight;
        CGFloat xPos = barWidth+(barWidth*i+barWidth*i);
        
        _MPWButton *button = [_MPWButton buttonWithType:UIButtonTypeCustom];
        button.tappableAreaOffset = UIOffsetMake(barWidth/2, self.height);
        [button setBackgroundColor:self.graphColor];
        if (_upSideDown) {
            button.frame=CGRectMake(xPos, animated ? -height : 0, barWidth, animated ? height+bounceHeight : height);
        } else {
            button.frame=CGRectMake(xPos, animated ? self.height : self.height-height, barWidth, animated ? height+bounceHeight : height);
        }
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = button.bounds;
        if (_upSideDown) {
            maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:button.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(radius, radius)].CGPath;
        } else {
            maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:button.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(radius, radius)].CGPath;
        }
        button.layer.mask = maskLayer;
        [button addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [self addSubview:button];
        
        if (self.coorDelegate) {
            [self.coorDelegate willLayoutIndex:i];
        }
        
        UILabel * detailLable = self.detailLabels[i];
        if (detailLable) {
            detailLable.alpha = animated ? 0 : 1;
            detailLable.center = CGPointMake(xPos+barWidth/2.0, _upSideDown ? height+8 : self.height-height-8);
            [self addSubview:detailLable];
        }
        if (animated) {
            [UIView animateWithDuration:self.animationDuration delay:i*0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                if (_upSideDown) {
                    button.y = 0;
                } else {
                    button.y = self.height-height-bounceHeight;
                }
            }completion:^(BOOL finished) {
                if (self.coorDelegate) {
                    [self.coorDelegate didLayoutIndex:i ofTopPoint:CGPointMake(xPos+barWidth/2.0, _upSideDown ? height : self.height-height)];
                }
                [UIView animateWithDuration:.15 animations:^{
                    if (_upSideDown) {
                        button.y = -bounceHeight;
                    } else {
                        button.y = self.height-height;
                    }
                } completion:^(BOOL finished) {
                    detailLable.alpha = 1;
                }];
            }];
        }
        
        [buttons addObject:button];
    }
    
    shouldAnimate=NO;
}

- (CGFloat)animationDuration
{
    return _animationDuration>0.0 ? _animationDuration : .25;
}

- (void)animate
{
    self.waitToUpdate=NO;
    shouldAnimate=YES;
    [self setNeedsDisplay];
}

@end
