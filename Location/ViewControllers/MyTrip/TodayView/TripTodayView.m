//
//  TripTodayView.m
//  TripMan
//
//  Created by taq on 11/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripTodayView.h"
#import "TripSummary.h"
#import "DaySummary+Fetcher.h"
#import "NSAttributedString+Style.h"

@interface TripTodayView () {
    CGFloat         _totalDistF;
    CGFloat         _totalDuringF;
    CGFloat         _jamDistF;
    CGFloat         _jamDuringF;
    CGFloat         _maxSpeedF;
    NSUInteger      _jamInTrafficLightN;
    CGFloat         _trafficLightWaitingF;
    NSUInteger      _tripCntN;
}

@end

@implementation TripTodayView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) __updateContent
{
    NSString * distStr = [NSString stringWithFormat:@"%.f", _totalDistF/1000.0];
    self.todayDist.attributedText = [NSAttributedString stringWithNumber:distStr font:[self.todayDist.font fontWithSize:50] color:self.todayDist.textColor andUnit:@"km" font:[self.todayDist.font fontWithSize:17] color:self.todayDist.textColor];
    
    NSString * duringStr = [NSString stringWithFormat:@"%.f", _totalDuringF/60.0];
    self.todayDuring.attributedText = [NSAttributedString stringWithNumber:duringStr font:[self.todayDuring.font fontWithSize:30] color:self.todayDuring.textColor andUnit:@"min" font:[self.todayDuring.font fontWithSize:14] color:self.todayDuring.textColor];
    
    NSString * maxSpeedStr = [NSString stringWithFormat:@"%.1f", _maxSpeedF*3.6];
    self.todayMaxSpeed.attributedText = [NSAttributedString stringWithNumber:maxSpeedStr font:[self.todayMaxSpeed.font fontWithSize:30] color:self.todayMaxSpeed.textColor andUnit:@"km/h" font:[self.todayMaxSpeed.font fontWithSize:14] color:self.todayMaxSpeed.textColor];
    
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)_tripCntN];
    
    self.jamDist.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.1f", _jamDistF/1000.0] font:[self.jamDist.font fontWithSize:17] color:self.jamDist.textColor andUnit:@"km" font:[self.jamDist.font fontWithSize:14] color:self.jamDist.textColor];
    self.jamDuring.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.f", _jamDuringF/60.0] font:[self.jamDuring.font fontWithSize:17] color:self.jamDuring.textColor andUnit:@"min" font:[self.jamDuring.font fontWithSize:14] color:self.jamDuring.textColor];
    
    self.trafficLightCnt.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%lu", (unsigned long)_jamInTrafficLightN] font:[self.trafficLightCnt.font fontWithSize:17] color:self.trafficLightCnt.textColor andUnit:@"处" font:[UIFont boldSystemFontOfSize:14] color:self.trafficLightCnt.textColor];
    self.trafficLightWaiting.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.1f", _trafficLightWaitingF/60.0] font:[self.trafficLightWaiting.font fontWithSize:17] color:self.trafficLightWaiting.textColor andUnit:@"min" font:[self.trafficLightWaiting.font fontWithSize:14] color:self.trafficLightWaiting.textColor];
}

- (void) updateWeek
{
    if (![self.weekSum.is_analyzed boolValue] || [self.weekSum.traffic_light_waiting integerValue] == 0) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeWeekSum:self.weekSum];
    }
    
    _totalDistF = [self.weekSum.total_dist floatValue];
    _totalDuringF = [self.weekSum.total_during floatValue];
    _jamDistF = [self.weekSum.jam_dist floatValue];
    _jamDuringF = [self.weekSum.jam_during floatValue];
    _maxSpeedF = [self.weekSum.max_speed floatValue];
    _jamInTrafficLightN = [self.weekSum.traffic_light_jam_cnt integerValue];
    _trafficLightWaitingF = [self.weekSum.traffic_light_waiting floatValue];
    _tripCntN = [self.weekSum.trip_cnt integerValue];
    
    WeekSummary * userSum = [[AnaDbManager sharedInst] userWeekSumForDeviceWeekSum:self.weekSum];
    if (userSum) {
        _totalDistF += [userSum.total_dist floatValue];
        _totalDuringF += [userSum.total_during floatValue];
        _jamDistF += [userSum.jam_dist floatValue];
        _jamDuringF += [userSum.jam_during floatValue];
        _maxSpeedF = MAX(_maxSpeedF, [userSum.max_speed floatValue]);
        _jamInTrafficLightN += [userSum.traffic_light_jam_cnt integerValue];
        _trafficLightWaitingF += [userSum.traffic_light_waiting floatValue];
        _tripCntN += [userSum.trip_cnt integerValue];
    }
    
    [self __updateContent];
}

- (void) updateDay
{
    if (![self.daySum.is_analyzed boolValue] || [self.daySum.traffic_light_waiting integerValue] == 0) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:self.daySum];
    }
    _totalDistF = [self.daySum.total_dist floatValue];
    _totalDuringF = [self.daySum.total_during floatValue];
    _jamDistF = [self.daySum.jam_dist floatValue];
    _jamDuringF = [self.daySum.jam_during floatValue];
    _maxSpeedF = [self.daySum.max_speed floatValue];
    _jamInTrafficLightN = [self.daySum.traffic_light_jam_cnt integerValue];
    _trafficLightWaitingF = [self.daySum.traffic_light_waiting floatValue];
    _tripCntN = [self.daySum validTripCount];
    
    DaySummary * userSum = [[AnaDbManager sharedInst] userDaySumForDeviceDaySum:self.daySum];
    if (userSum) {
        _totalDistF += [userSum.total_dist floatValue];
        _totalDuringF += [userSum.total_during floatValue];
        _jamDistF += [userSum.jam_dist floatValue];
        _jamDuringF += [userSum.jam_during floatValue];
        _maxSpeedF = MAX(_maxSpeedF, [userSum.max_speed floatValue]);
        _jamInTrafficLightN += [userSum.traffic_light_jam_cnt integerValue];
        _trafficLightWaitingF += [userSum.traffic_light_waiting floatValue];
        _tripCntN += [userSum validTripCount];
    }
    
    [self __updateContent];
}

@end
