//
//  TripTodayView.m
//  TripMan
//
//  Created by taq on 11/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripTodayView.h"
#import "TripSummary.h"

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

- (void)setWeekSum:(WeekSummary *)weekSum
{
    _weekSum = weekSum;
    _daySum = nil;
}

- (void)setDaySum:(DaySummary *)daySum
{
    _daySum = daySum;
    _weekSum = nil;
}

- (void) update
{
    if (_daySum) {
        [self updateDay];
    } else if (_weekSum) {
        [self updateWeek];
    }
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
    
    self.todayDist.text = [NSString stringWithFormat:@"%.1fkm", totalDist/1000.0];
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)tripCnt];
    self.todayDuring.text = [NSString stringWithFormat:@"%.fmin", totalDuring/60.0];
    self.todayMaxSpeed.text = [NSString stringWithFormat:@"%.1fkm/h", maxSpeed*3.6];
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
    
    self.todayDist.text = [NSString stringWithFormat:@"%.1fkm", totalDist/1000.0];
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.daySum.all_trips.count];
    self.todayDuring.text = [NSString stringWithFormat:@"%.fmin", totalDuring/60.0];
    self.todayMaxSpeed.text = [NSString stringWithFormat:@"%.1fkm/h", maxSpeed*3.6];
    self.jamDist.text = [NSString stringWithFormat:@"%.1fkm", jamDist/1000.0];
    self.jamDuring.text = [NSString stringWithFormat:@"%.fmin", jamDuring/60.0];
    self.trafficLightCnt.text = [NSString stringWithFormat:@"%lu处", (unsigned long)jamInTrafficLight];
    self.trafficLightWaiting.text = [NSString stringWithFormat:@"%.1fmin", trafficLightWaiting/60.0];
}

@end
