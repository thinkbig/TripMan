//
//  CarTripCell.m
//  TripMan
//
//  Created by taq on 12/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarTripCell.h"

@implementation CarTripHeader

- (void) addSegmentView:(UIView*)view
{
    view.frame = self.segmentContainer.bounds;
    [self.segmentContainer addSubview:view];
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation CarTripSliderCell

- (void) setSliderView:(UIView*)view
{
    view.frame = self.contentView.bounds;
    [self.contentView addSubview:view];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for (UIView * view in self.contentView.subviews) {
        view.frame = self.contentView.bounds;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation CarTripCarouselCell

- (void) setCarouselView:(UIView*)view
{
    view.frame = self.contentView.bounds;
    [self.contentView addSubview:view];
    
    self.noResultLabel.hidden = YES;
}

- (void) showNoResult:(BOOL)show
{
    self.noResultLabel.hidden = !show;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for (UIView * view in self.contentView.subviews) {
        view.frame = self.contentView.bounds;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation WeekSumCell

- (void)awakeFromNib
{
    self.xCoorBarView.coorStrArray = @[@"周日", @"周一", @"周二", @"周三", @"周四", @"周五", @"周六"];
    self.duringBarView.upSideDown = YES;
    self.distBarView.showBottomLine = NO;
    self.duringBarView.showBottomLine = NO;
    self.distColorView.layer.cornerRadius = CGRectGetHeight(self.distColorView.bounds)/2.0;
    self.duringColorView.layer.cornerRadius = CGRectGetHeight(self.duringColorView.bounds)/2.0;
    
    self.distBarView.graphColor = [UIColor cyanColor];
    self.duringBarView.graphColor = [UIColor greenColor];
}

- (void) animWithDelay:(CGFloat)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.distBarView animate];
        [self.duringBarView animate];
    });
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation WeekJamCell

- (void)awakeFromNib
{
    self.xCoorBarView.coorStrArray = @[@"周日", @"周一", @"周二", @"周三", @"周四", @"周五", @"周六"];
    self.jamDuringView.curved = YES;
    self.jamCountView.curved = YES;
    self.duringColorView.layer.cornerRadius = CGRectGetHeight(self.duringColorView.bounds)/2.0;
    self.countColorView.layer.cornerRadius = CGRectGetHeight(self.countColorView.bounds)/2.0;
    
    self.jamDuringView.graphColor = [UIColor cyanColor];
    self.jamCountView.graphColor = [UIColor greenColor];
    self.jamCountView.fillColors = @[[UIColor colorWithRed:0.251 green:1.0 blue:0.232 alpha:0.400],[UIColor colorWithRed:0.282 green:1.0 blue:0.945 alpha:0.900]];
}

- (void) animWithDelay:(CGFloat)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.jamDuringView animate];
        [self.jamCountView animate];
    });
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation WeekTrafficLightCell

- (void)awakeFromNib
{
    self.lightCountView.upSideDown = YES;
    self.lightDuringView.showBottomLine = NO;
    self.lightDuringView.showBottomLine = NO;
    
    self.lightDuringView.graphColor = [UIColor cyanColor];
    self.lightCountView.graphColor = [UIColor greenColor];
    
    self.duringColorView.layer.cornerRadius = CGRectGetHeight(self.duringColorView.bounds)/2.0;
    self.countColorView.layer.cornerRadius = CGRectGetHeight(self.countColorView.bounds)/2.0;
}

- (void) animWithDelay:(CGFloat)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.lightDuringView animate];
        [self.lightCountView animate];
    });
}

@end
