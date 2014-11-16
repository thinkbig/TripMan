//
//  TripTodayView.m
//  TripMan
//
//  Created by taq on 11/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripTodayView.h"

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

- (void) updateWithTripsToday:(NSArray*)trips
{
    CGFloat totalDist = 0;
    CGFloat totalDuring = 0;
    CGFloat jamDist = 0;
    CGFloat jamDuring = 0;
    NSUInteger trafficLightCnt = 0;
    CGFloat maxSpeed = 0;
    
    for (TripSummary * sum in trips) {
        totalDist += [sum.total_dist floatValue];
        totalDuring += [sum.total_during floatValue];
        jamDist += [sum.traffic_jam_dist floatValue];
        jamDuring += [sum.traffic_jam_during floatValue];
        trafficLightCnt += [sum.traffic_light_cnt integerValue];
        maxSpeed = MAX(maxSpeed, [sum.max_speed floatValue]);
    }
    
    self.todayDist.text = [NSString stringWithFormat:@"%.1fkm", totalDist/1000.0];
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)trips.count];
    self.todayDuring.text = [NSString stringWithFormat:@"%.fmin", totalDuring/60.0];
    self.todayMaxSpeed.text = [NSString stringWithFormat:@"%.1fkm/h", maxSpeed*3.6];
    self.jamDist.text = [NSString stringWithFormat:@"%.1fkm", jamDist/1000.0];
    self.jamDuring.text = [NSString stringWithFormat:@"%.fmin", jamDuring/60.0];
    self.trafficLightCnt.text = [NSString stringWithFormat:@"%lu处", (unsigned long)trafficLightCnt];
    self.trafficLightWaiting.text = @"计算中";
}

@end
