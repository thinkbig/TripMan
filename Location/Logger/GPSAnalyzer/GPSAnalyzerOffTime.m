//
//  GPSAnalyzerOffTime.m
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSAnalyzerOffTime.h"
#import "GPSAnalyzerDB.h"
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
#import "TrafficInfo.h"
#import "TurningInfo.h"
#import "ParkingRegion.h"

@interface GPSAnalyzerOffTime ()

@property (nonatomic, strong) GPSAnalyzerDB *           db;

@end

@implementation GPSAnalyzerOffTime

- (id)init
{
    self = [super init];
    if (self) {
        self.db = [[GPSAnalyzerDB alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tripStatChange:) name:kNotifyTripStatChange object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tripStatChange:(NSNotification *)notification
{
    NSLog(@"################# recieve drive stat change = %@", notification.userInfo);
    NSNumber * inTrip = notification.userInfo[@"inTrip"];
    NSDate * statDate = notification.userInfo[@"date"];
    if (nil == statDate) {
        statDate = [NSDate date];
    }
    if (nil != inTrip) {
        BOOL isDriving = [inTrip boolValue];

        // check unfinished trip
//        GPSAnalyzeSumItem * unfinishedTrip = [_db unfinishedTrip];
//        if (unfinishedTrip) {
//            // has unfinished trip
//            [_db endTrip:unfinishedTrip.db_id atDate:statDate];
//        }
//        if (isDriving) {
//            [_db beginNewTripAt:statDate];
//        }
        
        TripsCoreDataManager * manger = [TripsCoreDataManager sharedManager];
        TripSummary * unfinishedSum = [manger unfinishedTrip];
        if (unfinishedSum) {
            unfinishedSum.end_date = statDate;
        }
        if (isDriving) {
            [manger newTripAt:statDate];
        }
        [manger commit];
    }
}

- (void)rollOutOfDateTrip
{
    [self.dbLogger flush];
    BOOL isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
    if (!isDriving)
    {
        TripsCoreDataManager * manager = [TripsCoreDataManager sharedManager];
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


- (void)analyzeTripForSum:(TripSummary*)item
{
    if (nil == item) {
        return;
    }
    
    GPSFMDBLogger * loggerDB = self.dbLogger;
    NSMutableArray * rawData = [NSMutableArray array];
    NSInteger offset = 0;
    NSInteger limit = 500;
    NSArray * logArr = [loggerDB selectLogFrom:item.start_date toDate:item.end_date offset:offset limit:limit];
    if (logArr.count == 0) {
        NSLog(@"not such trip from %@ to %@", item.start_date, item.end_date);
        return;
    }
    
    GPSLogItem * stLogItem = [GPSAnalyzerOffTime modifyStartPoint:item.start_date];
    if (stLogItem) {
        // check the modified start point is valid
        GPSLogItem * logItem = logArr[0];
        CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:[logItem.latitude doubleValue] longitude:[logItem.longitude doubleValue]];
        CLLocation * lastLoc = [[CLLocation alloc] initWithLatitude:[stLogItem.latitude doubleValue] longitude:[stLogItem.longitude doubleValue]];
        CLLocationDistance distance = [lastLoc distanceFromLocation:curLoc];
        if (distance < 1200) {
            // the modified start point is valid, add to array
            [rawData addObject:stLogItem];
            // extimate the start time
            stLogItem.timestamp = [logItem.timestamp dateByAddingTimeInterval:-distance/cAvgDrivingSpeed];
            item.start_date = stLogItem.timestamp;
        }
    }
    
    while (logArr.count > 0) {
        [rawData addObjectsFromArray:logArr];
        offset += logArr.count;
        logArr = [loggerDB selectLogFrom:item.start_date toDate:item.end_date offset:offset limit:limit];
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
    if (realEndIdx != rawData.count - 1 && item.end_date) {
        // must be already ended trip, modify it's end timestamp
        item.end_date = endLogItem.timestamp;
    }
    
    TripsCoreDataManager * manager = [TripsCoreDataManager sharedManager];
    
    NSArray * smoothData = [GPSOffTimeFilter smoothGPSData:[rawData subarrayWithRange:NSMakeRange(0, realEndIdx)] iteratorCnt:3];
    
    // update analyze summary info
    GPSTripSummaryAnalyzer * oneTripAna = [GPSTripSummaryAnalyzer new];
    [oneTripAna updateGPSDataArray:smoothData];
    
    item.total_dist = @(oneTripAna.total_dist);
    item.total_during = @(oneTripAna.total_during);
    item.avg_speed = @(oneTripAna.avg_speed);
    item.max_speed = @(oneTripAna.max_speed);
    item.traffic_jam_dist = @(oneTripAna.traffic_jam_dist);
    item.traffic_jam_during = @(oneTripAna.traffic_jam_during);
    item.traffic_avg_speed = @(oneTripAna.traffic_avg_speed);
    item.traffic_jam_cnt = @(oneTripAna.traffic_jam_cnt);
    item.is_analyzed = @YES;
    
    // update analyze environment info
    EnvInfo * env_info = [manager environmentForTrip:item];
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
    GPSAcceleratorAnalyzer * acceAnalyzer = [GPSAcceleratorAnalyzer new];
    [acceAnalyzer updateGPSDataArray:smoothData];
    DrivingInfo * drive_info = [manager drivingInfoForTrip:item];
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
    drive_info.is_analyzed = @YES;
    
    // update turning info
    GPSTurningAnalyzer * turningAnalyzer = [GPSTurningAnalyzer new];
    [turningAnalyzer updateGPSDataArray:smoothData];
    TurningInfo * turning_info = [manager turningInfoForTrip:item];
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
    
    
    // update start and end location region
    [manager startRegionCenter:[stLogItem locationCoordinate] toRegionCenter:[endLogItem locationCoordinate] forTrip:item];
    
    [manager commit];
}

- (void)analyzeAllFinishedTrip:(BOOL)force
{
    [self rollOutOfDateTrip];
    
    TripsCoreDataManager * manager = [TripsCoreDataManager sharedManager];
    NSArray * trips = force ? [manager allTrips] : [manager unAnalyzedTrips];
    for (TripSummary * item in trips)
    {
        [self analyzeTripForSum:item];
    }
}
- (TripSummary*)analyzeUnFinishedTrip
{
    [self rollOutOfDateTrip];
    
    TripSummary * unfinishedTrip = [[TripsCoreDataManager sharedManager] unfinishedTrip];
    [self analyzeTripForSum:unfinishedTrip];
    
    return unfinishedTrip;
}

//- (GPSAnalyzeSumItem*)old_analyzeUnFinishedTrip
//{
//    [self old_rollOutOfDateTrip];
//    
//    GPSAnalyzeSumItem * unfinishedTrip = [_db unfinishedTrip];
//    [self old__realAnalyzeTrip:unfinishedTrip];
//    
//    return unfinishedTrip;
//}

- (NSArray*)tripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate forceAnalyze:(BOOL)force
{
    [self analyzeAllFinishedTrip:force];
    NSArray * returnTrips = [[TripsCoreDataManager sharedManager] tripStartFrom:fromDate toDate:toDate];
    for (TripSummary * sum in returnTrips) {
        if (nil == sum.end_date) {
            [self analyzeTripForSum:sum];
        }
    }
    return returnTrips;
}


+ (GPSLogItem*)modifyStartPoint:(NSDate*)origStart
{
    GPSEventItem * stRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:origStart ofType:eGPSEventExitRegion];
    if (nil == stRegion) {
        stRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:origStart ofType:eGPSEventMonitorRegion];
    }
    if (stRegion) {
        return [[GPSLogItem alloc] initWithEventItem:stRegion];
    }
    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)old_rollOutOfDateTrip
{
    [self.dbLogger flush];
    BOOL isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
    if (!isDriving)
    {
        GPSAnalyzeSumItem * unfinishedTrip = [_db unfinishedTrip];
        
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
                [_db endTrip:unfinishedTrip.db_id atDate:endItem.timestamp];
            } else {
                NSDictionary * lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
                NSDate * date = lastGoodGPS[@"timestamp"];
                if (date && [[NSDate date] timeIntervalSinceDate:date] > cOntOfDateThreshold) {
                    [_db endTrip:unfinishedTrip.db_id atDate:date];
                }
            }
        }
    }
}

- (void)old__realAnalyzeTrip:(GPSAnalyzeSumItem*)item
{
    if (nil == item) {
        return;
    }
    
    GPSFMDBLogger * loggerDB = self.dbLogger;
    NSMutableArray * rawData = [NSMutableArray array];
    NSInteger offset = 0;
    NSInteger limit = 500;
    NSArray * logArr = [loggerDB selectLogFrom:item.start_date toDate:item.end_date offset:offset limit:limit];
    if (logArr.count == 0) {
        NSLog(@"not such trip from %@ to %@", item.start_date, item.end_date);
        return;
    }
    
    GPSLogItem * stItem = [GPSAnalyzerOffTime modifyStartPoint:item.start_date];
    if (stItem) {
        // check the modified start point is valid
        GPSLogItem * item = logArr[0];
        CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:[item.latitude doubleValue] longitude:[item.longitude doubleValue]];
        CLLocation * lastLoc = [[CLLocation alloc] initWithLatitude:[stItem.latitude doubleValue] longitude:[stItem.longitude doubleValue]];
        CLLocationDistance distance = [lastLoc distanceFromLocation:curLoc];
        if (distance < 1200) {
            // the modified start point is valid, add to array
            [rawData addObject:stItem];
        }
    }
    
    while (logArr.count > 0) {
        [rawData addObjectsFromArray:logArr];
        offset += logArr.count;
        logArr = [loggerDB selectLogFrom:item.start_date toDate:item.end_date offset:offset limit:limit];
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
    if (realEndIdx != rawData.count - 1 && item.end_date) {
        // must be already ended trip, modify it's end location
        //[_db endTrip:item.db_id atDate:((GPSLogItem*)rawData[realEndIdx-1]).timestamp];       // the end date will be updated later
        item.end_date = ((GPSLogItem*)rawData[realEndIdx-1]).timestamp;
    }
    
    NSArray * smoothData = [GPSOffTimeFilter smoothGPSData:[rawData subarrayWithRange:NSMakeRange(0, realEndIdx)] iteratorCnt:3];
    
    // update analyze summary info
    GPSTripSummaryAnalyzer * oneTripAna = [GPSTripSummaryAnalyzer new];
    [oneTripAna updateGPSDataArray:smoothData];
    item.total_dist = @(oneTripAna.total_dist);
    item.total_during = @(oneTripAna.total_during);
    item.avg_speed = @(oneTripAna.avg_speed);
    item.max_speed = @(oneTripAna.max_speed);
    item.traffic_jam_dist = @(oneTripAna.traffic_jam_dist);
    item.traffic_jam_during = @(oneTripAna.traffic_jam_during);
    
    [_db updateAnalyzeItem:item analyzeFinished:YES];
    
    // update analyze environment info
    AnalyzeEnvItem * envItem = [[AnalyzeEnvItem alloc] initWithTripId:item.db_id];
    envItem.day_dist = @(oneTripAna.day_dist);
    envItem.day_during = @(oneTripAna.day_during);
    envItem.day_avg_speed = @(oneTripAna.day_avg_speed);
    envItem.day_max_speed = @(oneTripAna.day_max_speed);
    envItem.night_dist = @(oneTripAna.night_dist);
    envItem.night_during = @(oneTripAna.night_during);
    envItem.night_avg_speed = @(oneTripAna.night_avg_speed);
    envItem.night_max_speed = @(oneTripAna.night_max_speed);
    
    [_db updateEnvItem:envItem analyzeFinished:YES];
    
    // update accelerator info
    GPSAcceleratorAnalyzer * acceAnalyzer = [GPSAcceleratorAnalyzer new];
    [acceAnalyzer updateGPSDataArray:smoothData];
    AnalyzeDrivingItem * acceItem = [[AnalyzeDrivingItem alloc] initWithTripId:item.db_id];
    acceItem.breaking_cnt = @(acceAnalyzer.breaking_cnt);
    acceItem.hard_breaking_cnt = @(acceAnalyzer.hard_breaking_cnt);
    acceItem.max_breaking_begin_speed = @(acceAnalyzer.max_breaking_begin_speed);
    acceItem.max_breaking_end_speed = @(acceAnalyzer.max_breaking_end_speed);
    acceItem.acce_cnt = @(acceAnalyzer.acce_cnt);
    acceItem.hard_acce_cnt = @(acceAnalyzer.hard_acce_cnt);
    acceItem.max_acce_begin_speed = @(acceAnalyzer.max_acce_begin_speed);
    acceItem.max_acce_end_speed = @(acceAnalyzer.max_acce_end_speed);
    acceItem.shortest_40 = @(acceAnalyzer.shortest_40);
    acceItem.shortest_60 = @(acceAnalyzer.shortest_60);
    acceItem.shortest_80 = @(acceAnalyzer.shortest_80);
    
    [_db updateDrivingItem:acceItem analyzeFinished:YES];
    
    // update turning info
    GPSTurningAnalyzer * turningAnalyzer = [GPSTurningAnalyzer new];
    [turningAnalyzer updateGPSDataArray:smoothData];
    AnalyzeTurningItem * turnItem = [[AnalyzeTurningItem alloc] initWithTripId:item.db_id];
    turnItem.left_turn_cnt = @(turningAnalyzer.left_turn_cnt);
    turnItem.left_turn_avg_speed = @(turningAnalyzer.left_turn_avg_speed);
    turnItem.left_turn_max_speed = @(turningAnalyzer.left_turn_max_speed);
    turnItem.right_turn_cnt = @(turningAnalyzer.right_turn_cnt);
    turnItem.right_turn_avg_speed = @(turningAnalyzer.right_turn_avg_speed);
    turnItem.right_turn_max_speed = @(turningAnalyzer.right_turn_max_speed);
    turnItem.turn_round_cnt = @(turningAnalyzer.turn_round_cnt);
    turnItem.turn_round_avg_speed = @(turningAnalyzer.turn_round_avg_speed);
    turnItem.turn_round_max_speed = @(turningAnalyzer.turn_round_max_speed);
    
    [_db updateTurningItem:turnItem analyzeFinished:YES];
}


- (void)old_analyzeAllFinishedTrip:(BOOL)force
{
    [self old_rollOutOfDateTrip];
    
    NSArray * trips = force ? [_db finishedTrip] : [_db finishedAndUnAnalyzedTrip];
    for (GPSAnalyzeSumItem * item in trips)
    {
        [self old__realAnalyzeTrip:item];
    }
}


- (NSArray*)old_analyzedResultFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit reverseOrder:(BOOL)reverse forceAnalyze:(BOOL)force
{
    [self old_analyzeAllFinishedTrip:force];
    return [_db analyzedResultFrom:fromDate toDate:toDate offset:offset limit:limit reverseOrder:reverse];
}


@end
