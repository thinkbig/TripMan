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
#import "GPSOffTimeFilter.h"
#import "CTRoute.h"

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
    if (gpsLogs.count < 2) {
        return;
    }
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
    
    [self filterJamData];
    [self analyzeTrafficSum];
    
    GPSLogItem * stLoc = gpsLogs[0];
    GPSLogItem * edLoc = [gpsLogs lastObject];
    
    // mark all jam with key point
    for (TSPair * pair in self.traffic_jams) {
        GPSLogItem * first = pair.first;
        GPSLogItem * second = pair.second;
        
        CGFloat first2St = [first distanceFrom:stLoc];
        CGFloat second2St = [second distanceFrom:stLoc];
        if ([first.timestamp timeIntervalSinceDate:stLoc.timestamp] < 60*5 && (second2St < 300 || MAX(first2St, second2St) < 500)) {
            continue;   // too close to start loc, just ignore
        }
        
        CGFloat first2Ed = [first distanceFrom:edLoc];
        CGFloat second2Ed = [second distanceFrom:edLoc];
        if ([edLoc.timestamp timeIntervalSinceDate:second.timestamp] < 60*5 && (first2Ed < 300 || MAX(first2Ed, second2Ed) < 500)) {
            continue;   // too close to end loc, just ignore
        }
        
        first.isKeyPoint = YES;
        second.isKeyPoint = YES;
    }

    // 关键点，没有做筛选前
    NSArray * keyRoute = [GPSOffTimeFilter keyRouteFromGPS:gpsLogs autoFilter:NO];
    
    // filteredRoute 表示精简的route，相邻2点表示一个step
    NSArray * filteredRoute = keyRoute;
    NSArray * lastRoute = nil;
    do {
        lastRoute = filteredRoute;
        filteredRoute = [GPSOffTimeFilter filterWithTurning:filteredRoute];
    } while (filteredRoute.count != lastRoute.count);
    
    // 这里计算totledist等全局信息
    [self calculateTotalInfo:filteredRoute];
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
    
    if (filteredRoute.count < 2) {
        // 不可能发生，仅仅是保护
        self.route = nil;
    } else {
        // 如果相邻filteredRoute，都很接近，则可能是转角点，合并这些点为一个step
        GPSLogItem * lastItem = filteredRoute[0];
        NSMutableArray * mergedRoute = [NSMutableArray arrayWithObject:lastItem];
        
        NSInteger lowQualityCnt = 0;
        for (int i = 1; i < filteredRoute.count-1; i++) {
            GPSLogItem * item = filteredRoute[i];
            GPSLogItem * itemNext = filteredRoute[i+1];
            CGFloat dist2Last = [item distanceFrom:lastItem];
            BOOL shouldAddItem = NO;
            if (fabs(item.stepAngle) > 30 || dist2Last > cRouteStepMax) {
                shouldAddItem = YES;
            } else if (fabs(item.stepAngle) > 18) {
                CGFloat dist2Next = [item distanceFrom:itemNext];
                if (dist2Last > cRouteStepMin && dist2Next > cRouteStepMin) {
                    shouldAddItem = YES;
                }
            }
            
            if (shouldAddItem) {
                [mergedRoute addObject:item];
                lastItem = item;
                item.quality = lowQualityCnt > 3 ? -1 : 1;
                lowQualityCnt = 0;
            } else if (item.stepAngle > 60) {
                if (item.stepAngle > 120) {
                    lowQualityCnt += 3;
                } else if (item.stepAngle > 80) {
                    lowQualityCnt += 2;
                } else {
                    lowQualityCnt += 1;
                }
            }
        }

        [mergedRoute addObject:[filteredRoute lastObject]];
        
        self.route = [CTRoute new];
        [self.route setCoorType:eCoorTypeGps];
        self.route.orig = [[CTBaseLocation alloc] initWithLogItem:mergedRoute[0]];
        self.route.dest = [[CTBaseLocation alloc] initWithLogItem:[mergedRoute lastObject]];
        
        NSMutableArray * realSteps = [NSMutableArray arrayWithCapacity:mergedRoute.count];
        lastItem = mergedRoute[0];
        NSUInteger routeIdx = 0;
        CTJam * curJam = nil;
        for (int i = 1; i < mergedRoute.count; i++) {
            GPSLogItem * curItem = mergedRoute[i];
            CTStep * step = [[CTStep alloc] init];
            step.from = [[CTBaseLocation alloc] initWithLogItem:lastItem];
            step.to = [[CTBaseLocation alloc] initWithLogItem:curItem];
            NSMutableArray * curJams = [NSMutableArray array];

            // match curItem
            NSString * seg = @"";
            NSMutableString * pathString = [NSMutableString string];
            NSMutableArray * accuArr = [NSMutableArray array];
            for (; routeIdx < keyRoute.count; routeIdx++)
            {
                GPSLogItem * rawItem = keyRoute[routeIdx];
                if (rawItem == curItem) {
                    if (curJam) {
                        curJam.to = [[CTBaseLocation alloc] initWithLogItem:curItem];
                        [curJams addObject:curJam];
                        // alloc a new one
                        curJam = [CTJam new];
                        curJam.from = [[CTBaseLocation alloc] initWithLogItem:curItem];
                    }
                    break;
                } else {
                    if (rawItem.horizontalAccuracy) {
                        [accuArr addObject:rawItem.horizontalAccuracy];
                    }
                    CLLocationCoordinate2D coor = [rawItem coordinate];
                    [pathString appendFormat:@"%@%.5f,%.5f", seg, coor.longitude, coor.latitude];
                    seg = @";";
                }
                
                if (rawItem.isKeyPoint) {
                    if (nil == curJam) {
                        curJam = [CTJam new];
                        curJam.from = [[CTBaseLocation alloc] initWithLogItem:rawItem];
                    } else {
                        curJam.to = [[CTBaseLocation alloc] initWithLogItem:rawItem];
                        [curJams addObject:curJam];
                        curJam = nil;
                    }
                }
            }
            if (pathString.length > 0) {
                step.path = [pathString copy];
            }
            if (curJams.count > 0) {
                step.jams = [curJams copy];
            }
            [step calculateQuality:accuArr];
            if (curItem.quality < 0) {
                step.quality = @(-1);
            }
            
            lastItem = curItem;
            
            // add to realSteps
            [realSteps addObject:step];
        }
        
        if (realSteps.count > 0) {
            self.route.steps = [realSteps copy];
        }
    }
}

- (NSString*) jsonRoute
{
    if (self.route) {
        return [self.route toJSONString];
    }
    return nil;
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
    
    CGFloat threshold = cInsTrafficJamSpeed;
    if (distance > cRegionRadiusThreshold) {
        threshold = cAvgTrafficJamSpeed;
    }

    if (during < 0 || (during > 0 && distance/during > cAvgNoiceSpeed)) {
        // regard as noise
        during = distance/cAvgDrivingSpeed;
    }

    //_total_dist += distance;
    //_total_during += during;
    
    CGFloat curSpeed = ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
    if (curSpeed <= 0 && during > 5) {
        curSpeed = distance/during;
        
        // filter the speed for noise
        if (curSpeed > 30) {
            if ([item.horizontalAccuracy doubleValue] > 100 || [self.lastItem.horizontalAccuracy doubleValue] > 100 || [item.timestamp timeIntervalSinceDate:self.lastItem.timestamp] > 60) {
                curSpeed = 10;
            } else if (curSpeed > 60/3.6) {
                curSpeed = 60/3.6;
            }
        }
    }

    if (_max_speed < curSpeed) {
        _max_speed = curSpeed;
    }
    
    if ([self checkDayOrNight:item.timestamp]) {
        //_day_dist += distance;
        //_day_during += during;
        _day_max_speed = MAX(_day_max_speed, curSpeed);
    } else {
        //_night_dist += distance;
        //_night_during += during;
        _night_max_speed = MAX(_night_max_speed, curSpeed);
    }
    
    if (curSpeed > threshold) {
        [self appendVerifiedTrafficJamItem];
    } else if ([item.speed floatValue] >= 0) {
        [_lastTrafficJam addObject:item];
    }
    
    self.lastItem = item;
    self.lastLoc = curLoc;
}

- (void) calculateTotalInfo:(NSArray*)routeArr
{
    if (routeArr.count < 2) {
        return;
    }
    
    GPSLogItem * lastItem = routeArr[0];
    for (int i = 1; i < routeArr.count; i++) {
        GPSLogItem * curItem = routeArr[i];
        CLLocationDistance distance = [curItem distanceFrom:lastItem];
        NSTimeInterval during = [curItem.timestamp timeIntervalSinceDate:lastItem.timestamp];
        
        _total_dist += distance;
        _total_during += during;
        
        if ([self checkDayOrNight:curItem.timestamp]) {
            _day_dist += distance;
            _day_during += during;
        } else {
            _night_dist += distance;
            _night_during += during;
        }
        
        lastItem = curItem;
    }
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
        
        if (jamDist < 100 || jamDuring < 20) {
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
