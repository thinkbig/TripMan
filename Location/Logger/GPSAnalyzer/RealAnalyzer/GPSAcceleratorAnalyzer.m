//
//  GPSAcceleratorAnalyzer.m
//  Location
//
//  Created by taq on 10/21/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSAcceleratorAnalyzer.h"
#import "GPSOffTimeFilter.h"

@implementation GPSAcceleratorAnalyzer

- (void) updateGPSDataArray:(NSArray*)gpsLogs
{
    // init
    self.breaking_cnt = 0;
    self.hard_breaking_cnt = 0;
    self.max_breaking_begin_speed = 0;
    self.max_breaking_end_speed = 0;
    self.acce_cnt = 0;
    self.hard_acce_cnt = 0;
    self.max_acce_begin_speed = 0;
    self.max_acce_end_speed = 0;
    self.shortest_40 = 0;
    self.shortest_60 = 0;
    self.shortest_80 = 0;
    
    if (gpsLogs.count < 2) {
        return;
    }
    
    CGFloat window = 5;     // 5 seconds
    NSInteger windowBeginIdx = 0;
    CGFloat maxAcceWithinWindow = 0;
    CGFloat maxBreakingWithinWindow = 0;
    GPSLogItem * last = [gpsLogs lastObject];
    GPSLogItem * lastStationary = nil;
    for (NSInteger i = 0; i < gpsLogs.count; i++)
    {
        GPSLogItem * item = gpsLogs[i];
        if ([item.horizontalAccuracy doubleValue] > 1000 || [last distanceFrom:item] < 30 || [last.timestamp timeIntervalSinceDate:item.timestamp] < 10) {
            continue;
        }
        
        GPSLogItem * windowBegin = gpsLogs[windowBeginIdx];
        if ([item.timestamp timeIntervalSinceDate:windowBegin.timestamp] >= window) {
            windowBeginIdx++;
            CGFloat difSpeed = [item.speed doubleValue] - [windowBegin.speed doubleValue];
            if (difSpeed > 0) {
                if (maxAcceWithinWindow < difSpeed) {
                    maxAcceWithinWindow = difSpeed;
                    self.max_acce_begin_speed = [windowBegin.speed doubleValue];
                    self.max_acce_end_speed = [item.speed doubleValue];
                }
            } else {
                if (maxBreakingWithinWindow < -difSpeed) {
                    maxBreakingWithinWindow = -difSpeed;
                    self.max_breaking_begin_speed = [windowBegin.speed doubleValue];
                    self.max_breaking_end_speed = [item.speed doubleValue];
                }
            }
        }
        
        CLLocationCoordinate2D coords;
        coords.latitude = [item.latitude doubleValue];
        coords.longitude = [item.longitude doubleValue];
        CGFloat curSpeed = ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
        
        CGFloat during = [item.timestamp timeIntervalSinceDate:lastStationary.timestamp];
        if (curSpeed < cInsStationarySpeed) {
            lastStationary = item;
        } else if (lastStationary) {
            if (curSpeed > 80.0/3.6) {
                if (self.shortest_80 == 0 && during > 4) {
                    self.shortest_80 = during;
                } else {
                    self.shortest_80 = MIN(self.shortest_80, during);
                }
            }
            if (curSpeed > 60.0/3.6) {
                if (self.shortest_60 == 0 && during > 3) {
                    self.shortest_60 = during;
                } else {
                    self.shortest_60 = MIN(self.shortest_60, during);
                }
            }
            if (curSpeed > 40.0/3.6) {
                if (self.shortest_40 == 0 && during > 2) {
                    self.shortest_40 = during;
                } else {
                    self.shortest_40 = MIN(self.shortest_40, during);
                }
            }
        }
        
        if (i > 0) {
            // break or accelerate
            GPSLogItem * lastItem = gpsLogs[i-1];
            CGFloat lastSpeed = ([lastItem.speed floatValue] < 0 ? 0 : [lastItem.speed floatValue]);
            CGFloat xDif = fabs([item.accelerationX doubleValue]-[lastItem.accelerationX doubleValue]);
            CGFloat yDif = fabs([item.accelerationY doubleValue]-[lastItem.accelerationY doubleValue]);
            CGFloat zDif = fabs([item.accelerationZ doubleValue]-[lastItem.accelerationZ doubleValue]);
            CGFloat mod = xDif + yDif + zDif;
            if (mod > 0.4) {
                if (curSpeed > lastSpeed) {
                    self.hard_acce_cnt++;
                } else {
                    self.hard_breaking_cnt++;
                }
            } else if (mod > 0.2) {
                if (curSpeed > lastSpeed) {
                    self.acce_cnt++;
                } else {
                    self.breaking_cnt++;
                }
            }
        }
    }
}

@end
