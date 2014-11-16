//
//  GPSOneTripAnalyzer.m
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "GPSTripSummaryAnalyzer.h"
#import "TrafficJam.h"
#import "TSPair.h"

@interface GPSTripSummaryAnalyzer ()

@property (nonatomic, strong) GPSLogItem *          lastItem;
@property (nonatomic, strong) CLLocation *          lastLoc;
@property (nonatomic, strong) NSMutableArray *      lastTrafficJam;
@property (nonatomic, strong) NSMutableArray *      traffic_jams;

@end

@implementation GPSTripSummaryAnalyzer

- (BOOL) checkDayOrNight:(NSDate*)date
{
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSMonthCalendarUnit |  NSHourCalendarUnit;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
    //NSInteger month = [comps month];
    NSInteger hour = [comps hour];
    return (hour >= 6 && hour < 19);        // 6am t0 6pm
}

- (void) updateGPSDataArray:(NSArray*)gpsLogs
{
    self.traffic_jams = [NSMutableArray array];
    self.lastTrafficJam = [NSMutableArray array];
    self.lastItem = nil;
    self.lastLoc = nil;
    
    self.total_dist = 0;
    self.total_during = 0;
    self.avg_speed = 0;
    self.max_speed = 0;
    self.traffic_jam_dist = 0;
    self.traffic_jam_during = 0;
    
    self.day_dist = 0;
    self.day_during = 0;
    self.day_avg_speed = 0;
    self.day_max_speed = 0;
    
    self.night_dist = 0;
    self.night_during = 0;
    self.night_avg_speed = 0;
    self.night_max_speed = 0;
    
    for (GPSLogItem * item in gpsLogs) {
        [self appendData:item];
    }
    
    [self appendVerifiedTrafficJamItem];
    if (self.total_during > 0) {
        self.avg_speed = _total_dist/_total_during;
    }
    if (self.day_during > 0) {
        self.day_avg_speed = _day_dist/_day_during;
    }
    if (self.night_during > 0) {
        self.night_avg_speed = _night_dist/_night_during;
    }
}

- (void) appendData:(GPSLogItem*)item
{    
    if (nil == self.lastItem) {
        self.lastItem = item;
        self.lastLoc = [[CLLocation alloc] initWithLatitude:[item.latitude doubleValue] longitude:[item.longitude doubleValue]];
        return;
    }
    CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:[item.latitude doubleValue] longitude:[item.longitude doubleValue]];
    CLLocationDistance distance = [self.lastLoc distanceFromLocation:curLoc];
    NSTimeInterval during = [item.timestamp timeIntervalSinceDate:self.lastItem.timestamp];

    if (during < 0 || (during > 0 && distance/during > cAvgNoiceSpeed)) {
        // regard as noise
        during = distance/cAvgDrivingSpeed;
    }
    CGFloat curSpeed = ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
    _max_speed = MAX(_max_speed, curSpeed);
    if (_total_dist <= 0) {
        // first point
        distance *= 1.414;
        during = distance/cAvgDrivingSpeed;
    }
    _total_dist += distance;
    _total_during += during;
    
    if ([self checkDayOrNight:item.timestamp]) {
        _day_dist += distance;
        _day_during += during;
        _day_max_speed = MAX(_day_max_speed, curSpeed);
    } else {
        _night_dist += distance;
        _night_during += during;
        _night_max_speed = MAX(_night_max_speed, curSpeed);
    }
    
    if (curSpeed > cAvgTrafficJamSpeed) {
        [self appendVerifiedTrafficJamItem];
    } else {
        [_lastTrafficJam addObject:item];
    }
    
    self.lastItem = item;
    self.lastLoc = curLoc;
}

- (NSArray*) getTrafficJams
{
    return [self.traffic_jams copy];
}

#pragma mark - private method

- (void) appendVerifiedTrafficJamItem
{
    NSArray * oldJamData = [self.lastTrafficJam copy];
    [self.lastTrafficJam removeAllObjects];
    
    if (oldJamData.count < 5) {
        return;
    }
    
    GPSLogItem * firstItem = oldJamData[0];
    GPSLogItem * lastItem = [oldJamData lastObject];
    
    CGFloat jamDist = [lastItem distanceFrom:firstItem];
    CGFloat jamDuring = [lastItem.timestamp timeIntervalSinceDate:firstItem.timestamp];
    
    if (jamDuring > 5) {
        self.traffic_jam_cnt++;
        _traffic_jam_dist += jamDist;
        _traffic_jam_during += jamDuring;
        [self.traffic_jams addObject:TSPairMake(firstItem, lastItem, nil)];
    }
    
//    CLLocation * lastJamLoc = nil;
//    GPSLogItem * lastJamItem = nil;
//    for (GPSLogItem * item in oldJamData)
//    {
//        if (nil == lastJamItem) {
//            lastJamItem = item;
//            lastJamLoc = [[CLLocation alloc] initWithLatitude:[item.latitude doubleValue] longitude:[item.longitude doubleValue]];
//        } else {
//            CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:[item.latitude doubleValue] longitude:[item.longitude doubleValue]];
//            NSTimeInterval during = [item.timestamp timeIntervalSinceDate:lastJamItem.timestamp];
//            CLLocationDistance distance = [lastJamLoc distanceFromLocation:curLoc];
//
//            lastJamItem = item;
//            lastJamLoc = curLoc;
//            
//            if (during < 0 || (during > 0 && distance/during > cAvgNoiceSpeed)) {
//                // regard as noise
//                continue;
//            }
//            _traffic_jam_dist += distance;
//            _traffic_jam_during += during;
//        }
//    }
//    
//    if (oldJamData.count > 5) {
//        self.traffic_jam_cnt++;
//    }
}

@end
