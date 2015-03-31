//
//  GPSAnalyzerOffTime.m
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSAnalyzerOffTime.h"
#import "GPSAnalyzerRealTime.h"
#import "GPSTripSummaryAnalyzer.h"
#import "GPSEndTraceAnalyzer.h"
#import "GPSAcceleratorAnalyzer.h"
#import "GPSTurningAnalyzer.h"
#import "GPSOffTimeFilter.h"
#import "BussinessDataProvider.h"
#import <CoreLocation/CoreLocation.h>
#import "TripSummary.h"
#import "DrivingInfo.h"
#import "WeatherInfo.h"
#import "EnvInfo.h"
#import "TrafficJam.h"
#import "TurningInfo.h"
#import "DaySummary+Fetcher.h"
#import "ParkingRegion.h"
#import "NSDate+Utilities.h"
#import "TSPair.h"

@implementation GPSAnalyzerOffTime

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tripStatChange:) name:kNotifyTripStatChange object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (TripsCoreDataManager *)manager
{
    if (nil == _manager) {
        return [AnaDbManager deviceDb];
    }
    return _manager;
}

- (void)tripStatChange:(NSNotification *)notification
{
    NSLog(@"################# recieve drive stat change = %@", notification.userInfo);
    NSNumber * inTrip = notification.userInfo[@"inTrip"];
    NSNumber * dropTrip = notification.userInfo[@"dropTrip"];
    NSDate * statDate = notification.userInfo[@"date"];
    if (nil == statDate) {
        statDate = [NSDate date];
    }
    if (nil != inTrip) {
        BOOL isDriving = [inTrip boolValue];
        
        TripsCoreDataManager * manger = self.manager;
        TripSummary * unfinishedSum = [manger unfinishedTrip];
        if (unfinishedSum) {
            unfinishedSum.end_date = statDate;
            unfinishedSum.region_group = nil;
            // the region is expired
            unfinishedSum.is_analyzed = @NO;
        }
        if (isDriving) {
            [manger newTripAt:statDate];
        }
        if (dropTrip && [dropTrip boolValue]) {
            [unfinishedSum delete];
        }
        [manger commit];
        
        if (unfinishedSum) {
            if (![dropTrip boolValue]) {
                [self analyzeTripForSum:unfinishedSum withAnalyzer:nil];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyTripDidEnd object:nil];
        }
    }
}

- (void)rollOutOfDateTrip
{
    [self.dbLogger flush];
    BOOL isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
    if (!isDriving)
    {
        TripsCoreDataManager * manager = self.manager;
        TripSummary * unfinishedTrip = [manager unfinishedTrip];
        
        if (unfinishedTrip) {
            GPSFMDBLogger * loggerDB = self.dbLogger;
            GPSEndTraceAnalyzer * ana = [GPSEndTraceAnalyzer new];
            
            NSInteger offset = 0;
            NSInteger limit = 500;
            NSArray * logArr = [loggerDB selectLogFrom:unfinishedTrip.start_date toDate:nil offset:offset limit:limit];
            if (logArr.count == 0) {
                NSLog(@"not such trip from %@ to now", unfinishedTrip.start_date);
                return;
            }
            GPSLogItem * endItem = nil;
            while (logArr.count > 0) {
                endItem = [ana traceGPSEndWithArray:logArr];
                if (endItem) {
                    break;
                }
                offset += logArr.count;
                logArr = [loggerDB selectLogFrom:unfinishedTrip.start_date toDate:nil offset:offset limit:limit];
            }
            
            if (endItem) {
                unfinishedTrip.end_date = endItem.timestamp;
                [manager commit];
            } else {
                NSDictionary * lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
                NSDate * date = lastGoodGPS[@"timestamp"];
                if (date && [[NSDate date] timeIntervalSinceDate:date] > cOntOfDateThreshold) {
                    unfinishedTrip.end_date = date;
                    [manager commit];
                }
            }
        }
    }
}


- (void)analyzeDaySum:(DaySummary*)daySum
{
    if (nil == daySum) {
        return;
    }
    TripsCoreDataManager * manager = self.manager;
    
    CGFloat total_dist = 0;
    CGFloat total_during = 0;
    CGFloat jam_dist = 0;
    CGFloat jam_during = 0;
    NSInteger traffic_heavy_jam_cnt = 0;
    NSInteger traffic_light_jam_cnt = 0;
    CGFloat traffic_light_waiting = 0;
    CGFloat max_speed = 0;
    NSArray * tripSums = [daySum validTrips];
    for (TripSummary * sum in tripSums) {
        if (![sum.is_valid boolValue]) {
            continue;
        }
        if (![sum.is_analyzed boolValue]) {
            [self analyzeTripForSum:sum withAnalyzer:nil];
        }
        total_dist += [sum.total_dist floatValue];
        total_during += [sum.total_during floatValue];
        jam_dist += [sum.traffic_jam_dist floatValue];
        jam_during += [sum.traffic_jam_during floatValue];
        traffic_heavy_jam_cnt += [sum.traffic_heavy_jam_cnt integerValue];
        traffic_light_jam_cnt += [sum.traffic_light_jam_cnt integerValue];
        traffic_light_waiting += [sum.traffic_light_waiting floatValue];
        max_speed = MAX(max_speed, [sum.max_speed floatValue]);
    }
    daySum.total_dist = @(total_dist);
    daySum.total_during = @(total_during);
    daySum.avg_speed = total_during > 0 ? @(total_dist/total_during) : @0;
    daySum.jam_dist = @(jam_dist);
    daySum.jam_during = @(jam_during);
    daySum.traffic_heavy_jam_cnt = @(traffic_heavy_jam_cnt);
    daySum.traffic_light_jam_cnt = @(traffic_light_jam_cnt);
    daySum.traffic_light_waiting = @(traffic_light_waiting);
    daySum.max_speed = @(max_speed);
    daySum.is_analyzed = @(YES);
    
    [manager commit];
}

- (void)analyzeWeekSum:(WeekSummary*)weekSum
{
    if (nil == weekSum) {
        return;
    }
    TripsCoreDataManager * manager = self.manager;

    CGFloat total_dist = 0;
    CGFloat total_during = 0;
    CGFloat jam_dist = 0;
    CGFloat jam_during = 0;
    NSInteger heavy_jam_cnt = 0;
    NSInteger traffic_light_jam_cnt = 0;
    CGFloat traffic_light_waiting = 0;
    CGFloat max_speed = 0;
    NSInteger trip_cnt = 0;
    NSArray * tripSums = [weekSum.all_days allObjects];
    for (DaySummary * sum in tripSums) {
        if (![sum.is_analyzed boolValue] || 0 == [sum.traffic_light_jam_cnt integerValue]) {
            [self analyzeDaySum:sum];
        }
        total_dist += [sum.total_dist floatValue];
        total_during += [sum.total_during floatValue];
        jam_dist += [sum.jam_dist floatValue];
        jam_during += [sum.jam_during floatValue];
        traffic_light_jam_cnt += [sum.traffic_light_jam_cnt integerValue];
        traffic_light_waiting += [sum.traffic_light_waiting floatValue];
        max_speed = MAX(max_speed, [sum.max_speed floatValue]);
        trip_cnt += [sum validTripCount];
        heavy_jam_cnt += [sum.traffic_heavy_jam_cnt integerValue];
    }
    weekSum.total_dist = @(total_dist);
    weekSum.total_during = @(total_during);
    weekSum.jam_dist = @(jam_dist);
    weekSum.jam_during = @(jam_during);
    weekSum.traffic_heavy_jam_cnt = @(heavy_jam_cnt);
    weekSum.traffic_light_jam_cnt = @(traffic_light_jam_cnt);
    weekSum.traffic_light_waiting = @(traffic_light_waiting);
    weekSum.max_speed = @(max_speed);
    weekSum.trip_cnt = @(trip_cnt);
    weekSum.is_analyzed = @(YES);
    
    [manager commit];
}

- (void)analyzeMonthSum:(MonthSummary*)monthSum
{
    if (nil == monthSum) {
        return;
    }
    
    CGFloat total_dist = 0;
    CGFloat total_during = 0;
    CGFloat jam_dist = 0;
    CGFloat jam_during = 0;
    CGFloat max_speed = 0;
    NSInteger trip_cnt = 0;
    NSInteger heavy_jam_cnt = 0;
    TripSummary *trip_most_dist = nil;
    TripSummary *trip_most_during = nil;
    TripSummary *trip_most_jam_during = nil;
    NSArray * tripSums = [monthSum.all_days allObjects];
    for (DaySummary * sum in tripSums) {
        if (![sum.is_analyzed boolValue] || 0 == [sum.traffic_light_jam_cnt integerValue]) {
            [self analyzeDaySum:sum];
        }
        total_dist += [sum.total_dist floatValue];
        total_during += [sum.total_during floatValue];
        jam_dist += [sum.jam_dist floatValue];
        jam_during += [sum.jam_during floatValue];
        heavy_jam_cnt += [sum.traffic_heavy_jam_cnt integerValue];
        max_speed = MAX(max_speed, [sum.max_speed floatValue]);
        trip_cnt += [sum validTripCount];
        for (TripSummary * realTrip in [sum validTrips]) {
            if ([trip_most_dist.total_dist floatValue] < [realTrip.total_dist floatValue]) {
                trip_most_dist = realTrip;
            }
            if ([trip_most_during.total_during floatValue] < [realTrip.total_during floatValue]) {
                trip_most_during = realTrip;
            }
            if ([trip_most_jam_during.traffic_jam_during floatValue] < [realTrip.traffic_jam_during floatValue]) {
                trip_most_jam_during = realTrip;
            }
        }
    }
    monthSum.total_dist = @(total_dist);
    monthSum.total_during = @(total_during);
    monthSum.jam_dist = @(jam_dist);
    monthSum.jam_during = @(jam_during);
    monthSum.traffic_heavy_jam_cnt = @(heavy_jam_cnt);
    monthSum.max_speed = @(max_speed);
    monthSum.trip_cnt = @(trip_cnt);
    monthSum.trip_most_dist = trip_most_dist;
    monthSum.trip_most_during = trip_most_during;
    monthSum.trip_most_jam_during = trip_most_jam_during;
    monthSum.is_analyzed = @(YES);
    
    [self.manager commit];
}

- (void)analyzeTripForSum:(TripSummary*)tripSum withAnalyzer:(NSDictionary*)anaDict
{
    if (nil == tripSum) {
        return;
    }
    
    GPSFMDBLogger * loggerDB = self.dbLogger;
    NSMutableArray * rawData = [NSMutableArray array];
    NSInteger offset = 0;
    NSInteger limit = 500;
    NSArray * logArr = [loggerDB selectLogFrom:tripSum.start_date toDate:tripSum.end_date offset:offset limit:limit];
    if (logArr.count == 0) {
        NSLog(@"not such trip from %@ to %@", tripSum.start_date, tripSum.end_date);
        return;
    }
    
    GPSLogItem * stLogItem = [self modifyStartPoint:tripSum firstGPSLog:logArr[0]];
    if (stLogItem) {
        // check the modified start point is valid
        GPSLogItem * logItem = logArr[0];
        CLLocationDistance distance = [stLogItem distanceFrom:logItem];
        if (distance < cStartLocErrorDist*2.5) {
            // the modified start point is valid, add to array
            [rawData addObject:stLogItem];
            // extimate the start time
            stLogItem.timestamp = [logItem.timestamp dateByAddingTimeInterval:-(distance*1.44)/cAvgDrivingSpeed];
            tripSum.start_date = stLogItem.timestamp;
        } else {
            stLogItem = nil;
        }
    }
    if (nil == stLogItem) {
        stLogItem = logArr[0];
    }
    
    while (logArr.count > 0) {
        [rawData addObjectsFromArray:logArr];
        offset += logArr.count;
        logArr = [loggerDB selectLogFrom:tripSum.start_date toDate:tripSum.end_date offset:offset limit:limit];
    }
    
    NSUInteger realEndIdx = rawData.count - 1;
    for (NSInteger i = rawData.count - 5; i > 0; i--) {
        CGFloat avgSpeed = ([(GPSLogItem*)rawData[i] safeSpeed] + [(GPSLogItem*)rawData[i+1] safeSpeed] + [(GPSLogItem*)rawData[i+2] safeSpeed] + [(GPSLogItem*)rawData[i+3] safeSpeed] + [(GPSLogItem*)rawData[i+4] safeSpeed]) / 5.0f;
        if (avgSpeed  >= cInsRunningSpeed) {
            realEndIdx = i+4;
            break;
        }
    }
    
    realEndIdx = MIN(realEndIdx+20, rawData.count - 1);
    GPSLogItem * endLogItem = rawData[realEndIdx];
    if (realEndIdx != rawData.count - 1 && tripSum.end_date) {
        // must be already ended trip, modify it's end timestamp
        tripSum.end_date = endLogItem.timestamp;
    }
    
    TripsCoreDataManager * manager = self.manager;
    NSArray * rawRoute = [rawData subarrayWithRange:NSMakeRange(0, realEndIdx)];
    NSArray * keyRoute = [GPSOffTimeFilter keyRouteFromGPS:rawRoute];
    NSArray * smoothData = [GPSOffTimeFilter smoothGPSData:rawRoute iteratorCnt:3];
    
    // update analyze summary info
    GPSTripSummaryAnalyzer * oneTripAna = [GPSTripSummaryAnalyzer new];
    [oneTripAna updateGPSDataArray:smoothData];
    
    tripSum.total_dist = @(oneTripAna.total_dist);
    tripSum.total_during = @(oneTripAna.total_during);
    tripSum.avg_speed = @(oneTripAna.avg_speed);
    tripSum.max_speed = @(oneTripAna.max_speed);
    tripSum.traffic_jam_dist = @(oneTripAna.traffic_jam_dist);
    tripSum.traffic_jam_during = @(oneTripAna.traffic_jam_during);
    tripSum.traffic_avg_speed = @(oneTripAna.traffic_avg_speed);
    
    NSString * keyRouteStr = [GPSOffTimeFilter routeToString:keyRoute];
    if (keyRouteStr.length > 0) {
        tripSum.addi_info = keyRouteStr;
    }
    
    NSArray * oldJams = [tripSum.traffic_jams allObjects];
    NSArray * jamArr = [oneTripAna getTrafficJams];
    __block NSInteger heavy_jam_cnt = 0;
    __block CGFloat traffic_jam_max_during = 0;
    [jamArr enumerateObjectsUsingBlock:^(TSPair * pair, NSUInteger idx, BOOL *stop) {
        TrafficJam * jam = nil;
        if (idx < oldJams.count) {
            jam = oldJams[idx];
        } else {
            jam = [manager allocTrafficInfoForTrip:tripSum];
        }
        
        GPSLogItem * startLog = pair.first;
        GPSLogItem * endLog = pair.second;
        jam.start_date = startLog.timestamp;
        jam.start_lat = startLog.latitude;
        jam.start_lon = startLog.longitude;
        jam.end_date = endLog.timestamp;
        jam.end_lat = endLog.latitude;
        jam.end_lon = endLog.longitude;
        jam.traffic_jam_dist = @([endLog distanceFrom:startLog]);
        jam.traffic_jam_during = @([jam.end_date timeIntervalSinceDate:jam.start_date]);
        if ([jam.traffic_jam_during doubleValue] > 0) {
            jam.traffic_avg_speed = @([jam.traffic_jam_dist doubleValue]/[jam.traffic_jam_during doubleValue]);
        }
        
        if ([jam.traffic_jam_during floatValue] > cHeavyTrafficJamThreshold && [endLogItem distanceFrom:endLog] > 100 && [stLogItem distanceFrom:startLog] > 100) {
            heavy_jam_cnt++;
            traffic_jam_max_during = MAX(traffic_jam_max_during, [jam.traffic_jam_during floatValue]);
        }
    }];
    for (NSInteger i = jamArr.count; i < oldJams.count; i++) {
        TrafficJam * removeJam = oldJams[i];
        [tripSum removeTraffic_jamsObject:removeJam];
    }
    tripSum.traffic_jam_max_during = @(traffic_jam_max_during);
    tripSum.traffic_heavy_jam_cnt = @(heavy_jam_cnt);
    
    // update analyze environment info
    EnvInfo * env_info = [manager environmentForTrip:tripSum];
    env_info.day_dist = @(oneTripAna.day_dist);
    env_info.day_during = @(oneTripAna.day_during);
    env_info.day_avg_speed = @(oneTripAna.day_avg_speed);
    env_info.day_max_speed = @(oneTripAna.day_max_speed);
    env_info.night_dist = @(oneTripAna.night_dist);
    env_info.night_during = @(oneTripAna.night_during);
    env_info.night_avg_speed = @(oneTripAna.night_avg_speed);
    env_info.night_max_speed = @(oneTripAna.night_max_speed);
    env_info.is_analyzed = @YES;
    
    // update analyze driving info
    GPSAcceleratorAnalyzer * acceAnalyzer = anaDict[@"AcceleratorAnalyzer"];
    if (nil == acceAnalyzer) {
        acceAnalyzer = [GPSAcceleratorAnalyzer new];
    }
    [acceAnalyzer updateGPSDataArray:smoothData];
    DrivingInfo * drive_info = [manager drivingInfoForTrip:tripSum];
    drive_info.breaking_cnt = @(acceAnalyzer.breaking_cnt);
    drive_info.hard_breaking_cnt = @(acceAnalyzer.hard_breaking_cnt);
    drive_info.max_breaking_begin_speed = @(acceAnalyzer.max_breaking_begin_speed);
    drive_info.max_breaking_end_speed = @(acceAnalyzer.max_breaking_end_speed);
    drive_info.acce_cnt = @(acceAnalyzer.acce_cnt);
    drive_info.hard_acce_cnt = @(acceAnalyzer.hard_acce_cnt);
    drive_info.max_acce_begin_speed = @(acceAnalyzer.max_acce_begin_speed);
    drive_info.max_acce_end_speed = @(acceAnalyzer.max_acce_end_speed);
    drive_info.shortest_40 = @(acceAnalyzer.shortest_40);
    drive_info.shortest_60 = @(acceAnalyzer.shortest_60);
    drive_info.shortest_80 = @(acceAnalyzer.shortest_80);
    drive_info.during_0_30 = @(acceAnalyzer.during_0_30);
    drive_info.during_30_60 = @(acceAnalyzer.during_30_60);
    drive_info.during_60_100 = @(acceAnalyzer.during_60_100);
    drive_info.during_100_NA = @(acceAnalyzer.during_100_NA);
    drive_info.is_analyzed = @YES;
    
    // update turning info
    GPSTurningAnalyzer * turningAnalyzer = anaDict[@"TurningAnalyzer"];
    if (nil == turningAnalyzer) {
        turningAnalyzer = [GPSTurningAnalyzer new];
    }
    [turningAnalyzer updateGPSDataArray:smoothData shouldSmooth:NO];
    TurningInfo * turning_info = [manager turningInfoForTrip:tripSum];
    turning_info.left_turn_cnt = @(turningAnalyzer.left_turn_cnt);
    turning_info.left_turn_avg_speed = @(turningAnalyzer.left_turn_avg_speed);
    turning_info.left_turn_max_speed = @(turningAnalyzer.left_turn_max_speed);
    turning_info.right_turn_cnt = @(turningAnalyzer.right_turn_cnt);
    turning_info.right_turn_avg_speed = @(turningAnalyzer.right_turn_avg_speed);
    turning_info.right_turn_max_speed = @(turningAnalyzer.right_turn_max_speed);
    turning_info.turn_round_cnt = @(turningAnalyzer.turn_round_cnt);
    turning_info.turn_round_avg_speed = @(turningAnalyzer.turn_round_avg_speed);
    turning_info.turn_round_max_speed = @(turningAnalyzer.turn_round_max_speed);
    turning_info.is_analyzed = @YES;
    
    NSArray * featurePts = [turningAnalyzer.filter featurePoints];
    NSMutableArray * ptsArr = [NSMutableArray arrayWithCapacity:featurePts.count];
    for (GPSLogItem * item in featurePts) {
        if (item.latitude && item.longitude) {
            [ptsArr addObject:@{@"lat": item.latitude, @"lon": item.longitude}];
        }
    }
    if (ptsArr) {
        NSData * ptsData = [NSKeyedArchiver archivedDataWithRootObject:ptsArr];
        turning_info.addi_data = ptsData;
    }
    
    // update start and end location region
    [manager startRegionCenter:[stLogItem coordinate] toRegionCenter:[endLogItem coordinate] forTrip:tripSum];
    
    // MUST after all analyze process, THEN set the analyzed flag
    if ([tripSum.region_group.is_temp boolValue]) {
        tripSum.is_analyzed = @NO;
    } else {
        tripSum.is_analyzed = @YES;
    }
    
    [manager commit];
}

- (void)analyzeAllFinishedTrip:(BOOL)force
{
    [self rollOutOfDateTrip];
    
    TripsCoreDataManager * manager = self.manager;
    NSArray * trips = force ? [manager allTrips] : [manager unAnalyzedTrips];
    for (TripSummary * item in trips)
    {
        [self analyzeTripForSum:item withAnalyzer:nil];
    }
}
- (TripSummary*)analyzeUnFinishedTrip
{
    [self rollOutOfDateTrip];
    
    TripSummary * unfinishedTrip = [self.manager unfinishedTrip];
    [self analyzeTripForSum:unfinishedTrip withAnalyzer:nil];
    
    return unfinishedTrip;
}

- (NSArray*)analyzeTripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate shouldUpdateGlobalInfo:(BOOL)update
{
    [self rollOutOfDateTrip];
    
    if (update) [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:10];
    
    NSArray * returnTrips = [self.manager tripStartFrom:fromDate toDate:toDate];
    NSEnumerator * enumerator = [returnTrips reverseObjectEnumerator];
    
    if (update) [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:20];
    
    TripSummary * lastSum = nil;
    NSInteger tolCnt = returnTrips.count;
    NSInteger curIdx = 1;
    for (TripSummary * sum in enumerator) {
        if (lastSum && ![lastSum.start_date isEqualToDateIgnoringTime:sum.start_date]) {
            DaySummary * lastDaysum = lastSum.day_summary;
            [self analyzeDaySum:lastDaysum];
            if (lastDaysum) {
                if (![lastSum.start_date isSameWeekAsDate:sum.start_date]) {
                    [self analyzeWeekSum:lastDaysum.week_summary];
                }
                if (![lastSum.start_date isSameMonthAsDate:sum.start_date]) {
                    [self analyzeMonthSum:lastDaysum.month_summary];
                }
            }
        }
        [self analyzeTripForSum:sum withAnalyzer:nil];
        lastSum = sum;
        
        if (update) [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:20+70*((CGFloat)curIdx/(CGFloat)tolCnt)];
        curIdx++;
    }
    if (lastSum) {
        [self analyzeDaySum:lastSum.day_summary];
        [self analyzeWeekSum:lastSum.day_summary.week_summary];
        [self analyzeMonthSum:lastSum.day_summary.month_summary];
    }
    if (update) [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:95];
    return returnTrips;
}


- (GPSLogItem*)modifyStartPoint:(TripSummary*)sum firstGPSLog:(GPSLogItem*)firstLog
{
    GPSEventItem * stRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:sum.start_date ofType:eGPSEventDriveEnd];
    if (nil == stRegion || ![stRegion isValidLocation]) {
        // if do not have the last end drive point, or do not have the lat lon
        // try get the last end driving point by trip sum
        TripSummary * prevTrip = [self.manager prevTripBy:sum];
        if (prevTrip) {
            stRegion = [[GPSEventItem alloc] init];
            stRegion.timestamp = prevTrip.end_date;
            stRegion.eventType = @(eGPSEventDriveEnd);
            stRegion.latitude = prevTrip.region_group.end_region.center_lat;
            stRegion.longitude = prevTrip.region_group.end_region.center_lon;
        }
    }
    
    if (stRegion && [stRegion isValidLocation]) {
        GPSLogItem * tmpItem = [[GPSLogItem alloc] initWithEventItem:stRegion];
        CLLocationDistance dist = [firstLog distanceFrom:tmpItem];
        NSTimeInterval during = [firstLog.timestamp timeIntervalSinceDate:stRegion.timestamp];
        if (dist < cStartLocErrorDist || during < 60*60*2) {
            return tmpItem;
        } else {
            stRegion = nil;
        }
    }
    
    if (nil == stRegion) {
        stRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:sum.start_date ofType:eGPSEventMonitorRegion];
    }
    if (stRegion) {
        return [[GPSLogItem alloc] initWithEventItem:stRegion];
    }
    return nil;
}

@end
