//
//  CarTripCell.m
//  TripMan
//
//  Created by taq on 12/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarTripCell.h"
#import "BussinessDataProvider.h"

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
    
    self.noResultView.hidden = YES;
}

- (void) showNoResult:(BOOL)show
{
    self.noResultView.hidden = !show;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for (UIView * view in self.contentView.subviews) {
        if (view != self.shadowView) {
            view.frame = self.contentView.bounds;
        }
    }
    [self.contentView bringSubviewToFront:self.shadowView];
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation WeekSumCell

- (void)awakeFromNib
{
    self.xCoorBarView.coorStrArray = @[@"周一", @"周二", @"周三", @"周四", @"周五", @"周六", @"周日"];
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

@implementation WeekSpeedCell

- (void)awakeFromNib
{
    self.maxColorView.layer.cornerRadius = CGRectGetHeight(self.maxColorView.bounds)/2.0;
    self.avgColorView.layer.cornerRadius = CGRectGetHeight(self.avgColorView.bounds)/2.0;
    
    self.maxSpeedView.graphColor = [UIColor cyanColor];
    self.avgSpeedView.graphColor = [UIColor greenColor];
}

- (void) animWithDelay:(CGFloat)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.maxSpeedView animate];
        [self.avgSpeedView animate];
    });
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation WeekJamCell

- (void)awakeFromNib
{
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

/////////////////////////////////////////////////////////////////////////////////////////

@implementation MonthBestCell

- (void)awakeFromNib
{
    self.tripDetailContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tripDetailContainer.layer.shadowOffset = CGSizeMake(0, -4);
    self.tripDetailContainer.layer.shadowOpacity = 0.6f;
    self.tripDetailContainer.layer.shadowRadius = 4.0f;
}

- (TripTicketView *)ticketView
{
    if (_ticketView) {
        return _ticketView;
    }
    
    _ticketView = [[[NSBundle mainBundle] loadNibNamed:@"TripTicketView" owner:self options:nil] lastObject];
    _ticketView.layer.cornerRadius = 10;
    _ticketView.frame = self.tripDetailContainer.bounds;
    [self.tripDetailContainer addSubview:_ticketView];
    
    return _ticketView;
}

- (void) updateWithTripSum:(TripSummary*)tripSum
{
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"MM月dd日 EEE"];
    self.timeLabel.text = [formatter stringFromDate:tripSum.start_date];
    
    [self.ticketView updateWithTripSummary:tripSum];
}

@end

