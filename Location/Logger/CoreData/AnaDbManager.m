//
//  AnaDbManager.m
//  TripMan
//
//  Created by taq on 1/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "AnaDbManager.h"
#import "DaySummary+Fetcher.h"
#import "NSDate+Utilities.h"
#import "ParkingRegion+Fetcher.h"
#import "TripFilter.h"

@interface AnaDbManager ()

@property (nonatomic, strong) NSString *        uid;
@property (nonatomic, strong) TripSummary *     latestTripInUserDb;     // the user db will not create new record, after async

@property (nonatomic, strong) TripsCoreDataManager *        deviceDbMgr;
@property (nonatomic, strong) TripsCoreDataManager *        userDbMgr;

@end


@implementation AnaDbManager

+ (instancetype)sharedInst {
    static AnaDbManager *_sharedInst = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInst = [[self alloc] init];
    });
    
    return _sharedInst;
}

+ (TripsCoreDataManager *) deviceDb {
    return ((AnaDbManager*)[self sharedInst]).deviceDbMgr;
}

+ (TripsCoreDataManager *) userDb {
    return ((AnaDbManager*)[self sharedInst]).userDbMgr;
}

- (TripsCoreDataManager *)deviceDbMgr
{
    if (nil == _deviceDbMgr) {
        _deviceDbMgr = [TripsCoreDataManager sharedManager];
    }
    return _deviceDbMgr;
}

- (TripsCoreDataManager *)userDbMgr
{
    if (nil == self.uid) {
        return nil;
    }
    if (nil == _userDbMgr) {
        _userDbMgr = [TripsCoreDataManager sharedManager];
        _userDbMgr.dbNamePrefix = self.uid;
    }
    return _userDbMgr;
}

- (void) commit {
    [self.deviceDbMgr commit];
    [self.userDbMgr commit];
}

- (void) dropDbAll {
    [self.deviceDbMgr dropDb];
    [self.userDbMgr dropDb];
}

- (void)switchUserDbById:(NSString *)uid
{
    if (uid == self.uid || [uid isEqualToString:self.uid]) {
        return;
    }
    
    // first logout, reset db info
    [_userDbMgr commit];
    _latestTripInUserDb = nil;
    _userDbMgr = nil;
    
    // then login with another user
    if (uid) {
        // import and download all user history trips
        // todo
        
        // after async, merge with local db
        
        [self mergeParkingLocation];
    }
}

- (void) mergeParkingLocation
{
    TripsCoreDataManager * userDb = self.userDbMgr;
    if (userDb) {
        NSArray * deviceParkings = [self.deviceDbMgr allParkingDetails];
        for (ParkingRegionDetail * detail in deviceParkings) {
            if ([detail.coreDataItem.is_temp boolValue] == NO) {
                ParkingRegionDetail * duplicateDetail = [userDb parkingDetailForCoordinate:detail.region.center minDist:500];
                if (duplicateDetail) {
                    [detail copyInfoFromAnother:duplicateDetail];
                }
            }
        }
    }
}

- (TripSummary *)latestTripInUserDb {
    if (nil == _latestTripInUserDb) {
        _latestTripInUserDb = [self.userDbMgr lastTrip];
    }
    return _latestTripInUserDb;
}

// wrapper for subdb

- (TripSummary*) lastTrip {
    TripSummary * lastSum = [self.deviceDbMgr lastTrip];
    if (nil == lastSum) {
        lastSum = [self latestTripInUserDb];
    }
    return lastSum;
}

- (NSDate*) lastTripDateInUserHistory {
    TripSummary * lastUserSum = [self latestTripInUserDb];
    return lastUserSum.start_date;
}

- (ParkingRegionDetail*) parkingDetailForCoordinate:(CLLocationCoordinate2D)coordinate minDist:(CGFloat)minDist
{
    ParkingRegionDetail * deviceDetail = [self.deviceDbMgr parkingDetailForCoordinate:coordinate minDist:minDist];
    if (nil == deviceDetail) {
        deviceDetail = [self.userDbMgr parkingDetailForCoordinate:coordinate minDist:minDist];
    }
    return deviceDetail;
}

- (ParkingRegion*) parkingRegioinForId:(NSString*)parkingId
{
    ParkingRegion * region = [self.deviceDbMgr parkingRegioinForId:parkingId];
    if (nil == region) {
        region = [self.userDbMgr parkingRegioinForId:parkingId];
    }
    return region;
}

- (NSArray*) tripsWithStartRegion:(ParkingRegion*)region tripLimit:(NSInteger)limit startDate:(NSDate*)stDate
{
    NSArray * rawGroups = [region.group_owner_st allObjects];
    
    // 删除起点和终点过于接近的点，要求大于1500米
    NSMutableArray * allGroups = [NSMutableArray arrayWithCapacity:rawGroups.count];
    for (RegionGroup * group in rawGroups) {
        CGFloat dist = [region distanseFrom:group.end_region];
        if (dist > 1500) {
            [allGroups addObject:group];
        }
    }
    
    NSArray * sortArr = [allGroups sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(RegionGroup * obj1, RegionGroup * obj2) {
        if (obj1.trips.count < obj2.trips.count) return NSOrderedDescending;
        else return NSOrderedAscending;
    }];
    
    NSMutableArray * bestTrips = [NSMutableArray array];
    [sortArr enumerateObjectsUsingBlock:^(RegionGroup * group, NSUInteger idx, BOOL *stop) {
        if (limit > 0 && idx >= limit) {
            *stop = YES;
        } else {
            CGFloat minDuring = MAXFLOAT;
            TripSummary * bestTrip = nil;
            for (TripSummary * sum in group.trips) {
                if (sum.end_date && minDuring > [sum.total_during floatValue]) {
                    minDuring = [sum.total_during floatValue];
                    bestTrip = sum;
                }
            }
            if (bestTrip) {
                [bestTrips addObject:bestTrip];
            }
        }
    }];
    return bestTrips;
}

- (TripSummary*) bestTripWithStartRegion:(ParkingRegion*)stRegion endRegion:(ParkingRegion*)edRegion startDate:(NSDate*)stDate
{
    RegionGroup * group = nil;
    for (RegionGroup * curGroup in stRegion.group_owner_st) {
        if (curGroup.end_region == edRegion) {
            group = curGroup;
            break;
        }
    }
    
    NSArray * trips = [group.trips allObjects];
    NSMutableArray * timeMatches = [NSMutableArray arrayWithCapacity:group.trips.count];
    for (TripSummary * sum in trips) {
        CGFloat timeGap = [stDate timeIntervalSinceDate:sum.start_date];
        if ((timeGap >= 0 && timeGap < 60*60) || (timeGap < 0 && timeGap > -60*10)) {
            [timeMatches addObject:sum];
        }
    }
    
    if (timeMatches.count == 0) {
        [timeMatches addObjectsFromArray:trips];
    }
    
    TripSummary * bestTrip = nil;
    CGFloat bestDuring = MAXFLOAT;
    for (TripSummary * sum in timeMatches) {
        CGFloat curDuring = [sum.total_during floatValue];
        if (curDuring > 0 && curDuring < bestDuring) {
            bestDuring = curDuring;
            bestTrip = sum;
        }
    }
    return bestTrip;
}

- (NSArray*) mostUsedParkingRegionLimit:(NSUInteger)limit
{
    NSArray * deviceRegion = [self.deviceDbMgr mostUsedParkingRegionLimit:limit];
    if (deviceRegion.count < limit) {
        NSArray * moreRegion = [self.userDbMgr mostUsedParkingRegionLimit:limit-deviceRegion.count];
        if (moreRegion) {
            return [deviceRegion arrayByAddingObjectsFromArray:moreRegion];
        }
    }
    return deviceRegion;
}

- (DaySummary*) userDaySumForDeviceDaySum:(DaySummary*)daySum
{
    NSDate * lastHistory = [self lastTripDateInUserHistory];
    if (daySum && [lastHistory compare:daySum.date_day] == NSOrderedDescending) {
        return [self.userDbMgr daySummaryByDay:daySum.date_day];
    }
    return nil;
}

- (WeekSummary*) userWeekSumForDeviceWeekSum:(WeekSummary*)weekSum
{
    NSDate * lastHistory = [self lastTripDateInUserHistory];
    if (weekSum && [lastHistory compare:weekSum.date_week] == NSOrderedDescending) {
        return [self.userDbMgr weekSummaryByDay:weekSum.date_week];
    }
    return nil;
}

- (MonthSummary*) userMonthSumForDeviceMonthSum:(MonthSummary*)monthSum
{
    NSDate * lastHistory = [self lastTripDateInUserHistory];
    if (monthSum && [lastHistory compare:monthSum.date_month] == NSOrderedDescending) {
        return [self.userDbMgr monthSummaryByDay:monthSum.date_month];
    }
    return nil;
}

- (TripSummary*) tripMostDistForMonthSum:(MonthSummary*)monthSum
{
    TripSummary * mostTrip = monthSum.trip_most_dist;
    MonthSummary * userSum = [self userMonthSumForDeviceMonthSum:monthSum];
    if (userSum) {
        TripSummary * oneTrip = userSum.trip_most_dist;
        if ([oneTrip.total_dist floatValue] > [mostTrip.total_dist floatValue]) {
            return oneTrip;
        }
    }
    return mostTrip;
}

- (TripSummary*) tripMostDuringForMonthSum:(MonthSummary*)monthSum
{
    TripSummary * mostTrip = monthSum.trip_most_during;
    MonthSummary * userSum = [self userMonthSumForDeviceMonthSum:monthSum];
    if (userSum) {
        TripSummary * oneTrip = userSum.trip_most_during;
        if ([oneTrip.total_during floatValue] > [mostTrip.total_during floatValue]) {
            return oneTrip;
        }
    }
    return mostTrip;
}

- (TripSummary*) tripMostJamDuringForMonthSum:(MonthSummary*)monthSum
{
    TripSummary * mostTrip = monthSum.trip_most_jam_during;
    MonthSummary * userSum = [self userMonthSumForDeviceMonthSum:monthSum];
    if (userSum) {
        TripSummary * oneTrip = userSum.trip_most_jam_during;
        if ([oneTrip.traffic_jam_during floatValue] > [mostTrip.traffic_jam_during floatValue]) {
            return oneTrip;
        }
    }
    return mostTrip;
}

@end

