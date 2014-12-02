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
}

@end

