//
//  TripTodayView.m
//  TripMan
//
//  Created by taq on 11/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripTodayView.h"
#import "TripSummary.h"
#import "NSAttributedString+Style.h"

@implementation TripTodayView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    self.tripCount.layer.cornerRadius = CGRectGetHeight(self.tripCount.bounds)/2.0f;
}

- (void) updateWeek
{
    if (![self.weekSum.is_analyzed boolValue] || [self.weekSum.traffic_light_waiting integerValue] == 0) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeWeekSum:self.weekSum];
    }
    CGFloat totalDist = [self.weekSum.total_dist floatValue];
    CGFloat totalDuring = [self.weekSum.total_during floatValue];
    CGFloat jamDist = [self.weekSum.jam_dist floatValue];
    CGFloat jamDuring = [self.weekSum.jam_during floatValue];
    CGFloat maxSpeed = [self.weekSum.max_speed floatValue];
    NSUInteger jamInTrafficLight = [self.weekSum.traffic_light_jam_cnt integerValue];
    CGFloat trafficLightWaiting = [self.weekSum.traffic_light_waiting floatValue];
    NSUInteger tripCnt = [self.weekSum.trip_cnt integerValue];
    
    NSString * distStr = [NSString stringWithFormat:@"%.f", totalDist/1000.0];
    self.todayDist.attributedText = [NSAttributedString stringWithNumber:distStr font:[UIFont boldSystemFontOfSize:50] color:UIColorFromRGB(0x82d13a) andUnit:@"km" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
    
    NSString * duringStr = [NSString stringWithFormat:@"%.f", totalDuring/60.0];
    self.todayDuring.attributedText = [NSAttributedString stringWithNumber:duringStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
    
    NSString * maxSpeedStr = [NSString stringWithFormat:@"%.1f", maxSpeed*3.6];
    self.todayMaxSpeed.attributedText = [NSAttributedString stringWithNumber:maxSpeedStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"km/h" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
    
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)tripCnt];
    self.jamDist.text = [NSString stringWithFormat:@"%.1fkm", jamDist/1000.0];
    self.jamDuring.text = [NSString stringWithFormat:@"%.fmin", jamDuring/60.0];
    self.trafficLightCnt.text = [NSString stringWithFormat:@"%lu处", (unsigned long)jamInTrafficLight];
    self.trafficLightWaiting.text = [NSString stringWithFormat:@"%.1fmin", trafficLightWaiting/60.0];
}

- (void) updateDay
{
    if (![self.daySum.is_analyzed boolValue] || [self.daySum.traffic_light_waiting integerValue] == 0) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:self.daySum];
    }
    CGFloat totalDist = [self.daySum.total_dist floatValue];
    CGFloat totalDuring = [self.daySum.total_during floatValue];
    CGFloat jamDist = [self.daySum.jam_dist floatValue];
    CGFloat jamDuring = [self.daySum.jam_during floatValue];
    CGFloat maxSpeed = [self.daySum.max_speed floatValue];
    NSUInteger jamInTrafficLight = [self.daySum.traffic_light_jam_cnt integerValue];
    CGFloat trafficLightWaiting = [self.daySum.traffic_light_waiting floatValue];
    
    NSString * distStr = [NSString stringWithFormat:@"%.f", totalDist/1000.0];
    self.todayDist.attributedText = [NSAttributedString stringWithNumber:distStr font:[UIFont boldSystemFontOfSize:50] color:UIColorFromRGB(0x82d13a) andUnit:@"km" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
    
    NSString * duringStr = [NSString stringWithFormat:@"%.f", totalDuring/60.0];
    self.todayDuring.attributedText = [NSAttributedString stringWithNumber:duringStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
    
    NSString * maxSpeedStr = [NSString stringWithFormat:@"%.1f", maxSpeed*3.6];
    self.todayMaxSpeed.attributedText = [NSAttributedString stringWithNumber:maxSpeedStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"km/h" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
    
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.daySum.all_trips.count];
    self.jamDist.text = [NSString stringWithFormat:@"%.1fkm", jamDist/1000.0];
    self.jamDuring.text = [NSString stringWithFormat:@"%.fmin", jamDuring/60.0];
    self.trafficLightCnt.text = [NSString stringWithFormat:@"%lu处", (unsigned long)jamInTrafficLight];
    self.trafficLightWaiting.text = [NSString stringWithFormat:@"%.1fmin", trafficLightWaiting/60.0];
}

@end
