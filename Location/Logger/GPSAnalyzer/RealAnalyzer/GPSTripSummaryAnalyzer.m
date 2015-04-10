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
    if (gpsLogs.count > 1) {
        self.total_during = [((GPSLogItem*)[gpsLogs lastObject]).timestamp timeIntervalSinceDate:((GPSLogItem*)gpsLogs[0]).timestamp];
    }
    if (self.total_during > 0) {
        self.avg_speed = _total_dist/_total_during;
    }
    if (self.day_during > 0) {
        self.day_avg_speed = _day_dist/_day_during;
    }
    if (self.night_during > 0) {
        self.night_avg_speed = _night_dist/_night_during;
    }
    
    [self filterJamData];
    [self analyzeTrafficSum];
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
    
    // filter the speed for noise
    if (curSpeed > 30) {
        if ([item.horizontalAccuracy doubleValue] > 100 || [self.lastItem.horizontalAccuracy doubleValue] > 100 || [item.timestamp timeIntervalSinceDate:self.lastItem.timestamp] > 60) {
            curSpeed = 10;
        }
    }
    
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
    
    if (curSpeed > cInsTrafficJamSpeed) {
        [self appendVerifiedTrafficJamItem];
    } else if ([item.speed floatValue] >= 0) {
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

- (BOOL) isValidJam:(TSPair*)jamPair
{
    GPSLogItem * jamStart = jamPair.first;
    GPSLogItem * jamEnd = jamPair.second;
    CGFloat thisDuring = [jamEnd.timestamp timeIntervalSinceDate:jamStart.timestamp];
    
    return thisDuring > 10;
}

- (void) filterJamData
{
    if (self.traffic_jams.count == 0) {
        return;
    }
    
    NSArray * rawJams = [self.traffic_jams copy];
    NSMutableArray * filteredJams = [NSMutableArray array];
    TSPair * lastPair = rawJams[0];
    for (NSInteger i = 1; i < rawJams.count; i++) {
        TSPair * curPair = rawJams[i];
        GPSLogItem * oneItem = lastPair.second;
        GPSLogItem * anotherItem = curPair.first;
        
        CGFloat jamDist = [anotherItem distanceFrom:oneItem];
        CGFloat jamDuring = [anotherItem.timestamp timeIntervalSinceDate:oneItem.timestamp];
        
        if (jamDist < 200 || jamDuring < 30) {
            lastPair.second = curPair.second;
        } else {
            if ([self isValidJam:lastPair]) {
                [filteredJams addObject:lastPair];
            }
            lastPair = curPair;
        }
    }
    if ([self isValidJam:lastPair]) {
        [filteredJams addObject:lastPair];
    }
    self.traffic_jams = filteredJams;
}

- (void) analyzeTrafficSum
{
    _traffic_jam_dist = 0;
    _traffic_jam_during = 0;
    NSArray * rawJams = [self.traffic_jams copy];
    for (TSPair * pair in rawJams) {
        GPSLogItem * oneItem = pair.first;
        GPSLogItem * anotherItem = pair.second;
        
        CGFloat jamDist = [anotherItem distanceFrom:oneItem];
        CGFloat jamDuring = [anotherItem.timestamp timeIntervalSinceDate:oneItem.timestamp];
        
        _traffic_jam_dist += jamDist;
        _traffic_jam_during += jamDuring;
    }
    
    _traffic_avg_speed = (_traffic_jam_during > 0) ? (_traffic_jam_dist/_traffic_jam_during) : 0;
}

- (void) appendVerifiedTrafficJamItem
{
    NSArray * oldJamData = [self.lastTrafficJam copy];
    [self.lastTrafficJam removeAllObjects];
    
    if (oldJamData.count < 2) {
        return;
    }
    
    GPSLogItem * firstItem = oldJamData[0];
    GPSLogItem * lastItem = [oldJamData lastObject];
    [self.traffic_jams addObject:TSPairMake(firstItem, lastItem, nil)];
}

@end
