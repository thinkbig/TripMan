//
//  TripsCoreDataManager.m
//  Location
//
//  Created by taq on 11/5/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripsCoreDataManager.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSDate+Utilities.h"
#import "GToolUtil.h"

//@interface TripsCoreDataManager (Private)
//
//- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithStoreType:(NSString *const)storeType
//                                                                 storeURL:(NSURL *)storeURL;
//- (NSURL *)sqliteStoreURL;
//
//@end

@interface TripsCoreDataManager ()

@property (nonatomic, strong) NSMutableArray *                  parkingDetails;

@end

@implementation TripsCoreDataManager

- (NSManagedObjectContext *)tripAnalyzerContent
{
    if (nil == _tripAnalyzerContent) {
        _tripAnalyzerContent = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _tripAnalyzerContent.parentContext = self.managedObjectContext;
    }
    return _tripAnalyzerContent;
}

- (NSURL *)applicationDocumentsDirectory {
    NSURL * url = [super applicationDocumentsDirectory];
    return [url URLByAppendingPathComponent:@"TripDb" isDirectory:YES];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSString *)databaseName
{
    NSString * name = [super databaseName];
    if (self.dbNamePrefix.length > 0) {
        name = [name stringByAppendingFormat:@"%@_", self.dbNamePrefix];
    }
    return name;
}

- (BOOL) dbExist
{
    NSURL *databaseDir = [self.applicationDocumentsDirectory URLByAppendingPathComponent:[self databaseName]];
    return [[[NSFileManager alloc] init] fileExistsAtPath:[databaseDir absoluteString]];
}

- (void) dropDb
{
    NSURL *databaseDir = [self.applicationDocumentsDirectory URLByAppendingPathComponent:[self databaseName]];
    [[[NSFileManager alloc] init] removeItemAtURL:databaseDir error:nil];
}

//- (void) dropDbAll
//{
//    NSFileManager* fm = [NSFileManager defaultManager];
//    NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:self.applicationDocumentsDirectory
//                                    includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
//                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
//                                                  errorHandler:nil];
//    
//    for (NSURL *url in dirEnumerator) {
//        NSNumber *isDirectory;
//        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
//        if (![isDirectory boolValue]) {
//            // This is a file - remove it
//            [fm removeItemAtURL:url error:NULL];
//        }
//    }
//}

- (CLCircularRegion*)circularRegionForCenter:(CLLocationCoordinate2D)center {
    return [[CLCircularRegion alloc] initWithCenter:center radius:cParkingRegionRadius identifier:@"parkingSpot"];
}

- (void) commit
{
    if ([self.tripAnalyzerContent hasChanges]) {
        [self.tripAnalyzerContent save:nil];
        [self.managedObjectContext performBlock:^{
            NSError * err = nil;
            [self.managedObjectContext save:&err];
            if (err) {
                DDLogWarn(@"Core Data commit fail: %ld", (long)err.code);
            }
        }];
    }
}

- (NSMutableArray *)parkingDetails
{
    if (nil == _parkingDetails) {
        [self loadAllParkingRegion];
    }
    return _parkingDetails;
}

- (void) loadAllParkingRegion
{
    NSArray * all = [ParkingRegion allInContext:self.tripAnalyzerContent];
    _parkingDetails = [NSMutableArray array];
    for (ParkingRegion * dbRegion in all) {
        CLCircularRegion * region = [self circularRegionForCenter:CLLocationCoordinate2DMake([dbRegion.center_lat doubleValue], [dbRegion.center_lon doubleValue])];
        ParkingRegionDetail * detail = [ParkingRegionDetail new];
        detail.coreDataItem = dbRegion;
        detail.region = region;
        [_parkingDetails addObject:detail];
    }
}

- (NSArray*) allParkingDetails
{
    return [self.parkingDetails copy];
}

- (ParkingRegionDetail*) parkingDetailForCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return nil;
    }
    
    CLLocation * loc = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    ParkingRegionDetail * nearestRegion = nil;
    CLLocationDistance nearestDist = MAXFLOAT;
    for (ParkingRegionDetail * detail in self.parkingDetails) {
        if (![detail.coreDataItem.is_temp boolValue] && [detail.region containsCoordinate:coordinate]) {
            CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:detail.region.center.latitude longitude:detail.region.center.longitude];
            CLLocationDistance dist = [curLoc distanceFromLocation:loc];
            if (dist < nearestDist) {
                dist = nearestDist;
                nearestRegion = detail;
            }
        }
    }
    return nearestRegion;
}

- (ParkingRegion*) addParkingLocation:(CLLocationCoordinate2D)coordinate modifyRegionCenter:(BOOL)ifModify
{
    ParkingRegionDetail * existDetail = [self parkingDetailForCoordinate:coordinate];
    if (existDetail) {
        if (ifModify) {
            CLLocationCoordinate2D newCoor = existDetail.region.center;
            newCoor = CLLocationCoordinate2DMake(0.7*newCoor.latitude+0.3*coordinate.latitude, 0.7*newCoor.longitude+0.3*coordinate.longitude);
            existDetail.region = [self circularRegionForCenter:newCoor];
            existDetail.coreDataItem.center_lat = @(newCoor.latitude);
            existDetail.coreDataItem.center_lon = @(newCoor.longitude);
        }
        return existDetail.coreDataItem;
    }
    
    // insert a new record
    ParkingRegion * newDbRegion = [ParkingRegion create:@{@"center_lat":@(coordinate.latitude), @"center_lon":@(coordinate.longitude), @"is_temp":@NO} inContext:self.tripAnalyzerContent];
    
    CLCircularRegion * region = [self circularRegionForCenter:coordinate];
    ParkingRegionDetail * detail = [ParkingRegionDetail new];
    detail.coreDataItem = newDbRegion;
    detail.region = region;
    [self.parkingDetails addObject:detail];
    
    return newDbRegion;
}

- (ParkingRegion*) tempParkingLocation:(CLLocationCoordinate2D)coordinate
{
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return nil;
    }
    
    ParkingRegion * tempDbRegion = nil;
    for (ParkingRegionDetail * detail in self.parkingDetails) {
        if ([detail.coreDataItem.is_temp boolValue]) {
            tempDbRegion = detail.coreDataItem;
            tempDbRegion.center_lat = @(coordinate.latitude);
            tempDbRegion.center_lon = @(coordinate.longitude);
        }
    }
    
    if (nil == tempDbRegion) {
        tempDbRegion = [ParkingRegion create:@{@"center_lat":@(coordinate.latitude), @"center_lon":@(coordinate.longitude), @"is_temp":@YES} inContext:self.tripAnalyzerContent];
    }
    
    CLCircularRegion * region = [self circularRegionForCenter:coordinate];
    ParkingRegionDetail * detail = [ParkingRegionDetail new];
    detail.coreDataItem = tempDbRegion;
    detail.region = region;
    [self.parkingDetails addObject:detail];
    
    return tempDbRegion;
}


- (TripSummary*) unfinishedTrip
{
    NSArray * trips = [TripSummary where:@"start_date!=nil AND end_date==nil" inContext:self.tripAnalyzerContent order:@{@"start_date": @"DESC"} limit:@(1)];
    if (trips.count > 0) {
        return trips[0];
    }
    return nil;
}

- (TripSummary*) prevTripBy:(TripSummary*)curTrip
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"start_date < %@", curTrip.start_date];
    NSArray * trips = [TripSummary where:predicate inContext:self.tripAnalyzerContent order:@{@"start_date": @"DESC"} limit:@(1)];
    if (trips.count > 0) {
        return trips[0];
    }
    return nil;
}

- (TripSummary*) lastTrip
{
    NSArray * trips = [TripSummary where:@"start_date!=nil" inContext:self.tripAnalyzerContent order:@{@"start_date": @"DESC"} limit:@(1)];
    if (trips.count > 0) {
        return trips[0];
    }
    return nil;
}

- (NSArray*) allTrips
{
    return [TripSummary where:@"start_date!=nil" inContext:self.tripAnalyzerContent order:@{@"start_date": @"DESC"}];
}

- (NSArray*) unAnalyzedTrips
{
    return [TripSummary where:@"start_date!=nil AND is_analyzed!=YES" inContext:self.tripAnalyzerContent order:@{@"start_date": @"DESC"}];
}

- (NSArray*) tripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate
{
    if (nil == fromDate) {
        fromDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    if (nil == toDate) {
        toDate = [NSDate distantFuture];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(start_date >= %@) AND (start_date <= %@)", fromDate, toDate];
    return [TripSummary where:predicate inContext:self.tripAnalyzerContent order:@{@"start_date": @"DESC"}];
}

- (NSArray*) mostUsefulTripsLimit:(NSUInteger)limit
{
    NSArray * regionGroupArr = nil;
    if (limit > 0) {
        regionGroupArr = [RegionGroup where:@"is_temp = NO" order:@{@"relative_trips_cnt": @"DESC"} limit:@(limit)];
    } else {
        regionGroupArr = [RegionGroup where:@"is_temp = NO" order:@{@"relative_trips_cnt": @"DESC"}];
    }
    
    NSMutableArray * bestTrips = [NSMutableArray array];
    for (RegionGroup * group in regionGroupArr) {
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

    return bestTrips;
}

- (NSArray*) mostUsedParkingRegionLimit:(NSUInteger)limit
{
    for (ParkingRegionDetail * parkLoc in self.parkingDetails) {
        NSUInteger tripCnt = 0;
        for (RegionGroup * group in parkLoc.coreDataItem.group_owner_ed) {
            tripCnt += group.trips.count;
        }
        parkLoc.parkingCnt = tripCnt;
    }

    NSArray * sortArr = [self.parkingDetails sortedArrayUsingComparator:^NSComparisonResult(ParkingRegionDetail * obj1, ParkingRegionDetail * obj2) {
        if (obj1.parkingCnt > obj2.parkingCnt) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        if (obj1.parkingCnt < obj2.parkingCnt) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    if (limit >= sortArr.count) {
        return sortArr;
    }
    return [sortArr subarrayWithRange:NSMakeRange(0, limit)];
}

- (void) setNeedAnalyzeForDay:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = [NSDate date];
    }
    NSDate * dayBegin = [dateDay dateAtStartOfDay];
    
    NSArray * daySums = [DaySummary where:@{@"date_day": dayBegin} inContext:self.tripAnalyzerContent];
    if (daySums.count > 0) {
        DaySummary * daySum = daySums[0];
        daySum.is_analyzed = @NO;
    }
    
    NSArray * weekSums = [WeekSummary where:@{@"date_week": dayBegin} inContext:self.tripAnalyzerContent];
    if (weekSums.count > 0) {
        WeekSummary * weekSum = weekSums[0];
        weekSum.is_analyzed = @NO;
    }
    
    [self commit];
}

- (DaySummary*) daySummaryByDay:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = [NSDate date];
    }
    NSDate * dayBegin = [dateDay dateAtStartOfDay];
    DaySummary * daySum = nil;
    NSArray * daySums = [DaySummary where:@{@"date_day": dayBegin} inContext:self.tripAnalyzerContent];
    if (daySums.count > 0) {
        daySum = daySums[0];
    }
    return daySum;
}

- (WeekSummary*) weekSummaryByDay:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = [NSDate date];
    }
    NSDate * dayBegin = [dateDay dateAtStartOfWeek];
    WeekSummary * weekSum = nil;
    NSArray * weekSums = [WeekSummary where:@{@"date_week": dayBegin} inContext:self.tripAnalyzerContent];
    if (weekSums.count > 0) {
        weekSum = weekSums[0];
    }

    return weekSum;
}

- (MonthSummary*) monthSummaryByDay:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = [NSDate date];
    }
    NSDate * dayBegin = [dateDay dateAtStartOfMonth];
    MonthSummary * monthSum = nil;
    NSArray * monthSums = [MonthSummary where:@{@"date_month": dayBegin} inContext:self.tripAnalyzerContent];
    if (monthSums.count > 0) {
        monthSum = monthSums[0];
    }
    
    return monthSum;
}


- (TripSummary*) newTripAt:(NSDate*)beginDate
{
    return [self newTripAt:beginDate endAt:nil];
}

- (TripSummary*) newTripAt:(NSDate*)beginDate endAt:(NSDate*)endDate
{
    if (nil == beginDate) {
        return nil;
    }
    TripSummary * newTrip = [TripSummary create:@{@"start_date": beginDate, @"is_analyzed":@NO} inContext:self.tripAnalyzerContent];
    if (endDate) {
        newTrip.end_date = endDate;
    }
        
    DaySummary * daySum = [self daySumForTrip:newTrip];
    [self weekSumForDay:daySum];
    [self monthSumForDay:daySum];
    
    return newTrip;
}


- (DaySummary*) daySumForTrip:(TripSummary*)tripSum
{
    if (nil == tripSum) {
        return nil;
    }
    if (tripSum.day_summary) {
        return tripSum.day_summary;
    }
    
    NSDate * dayBegin = [tripSum.start_date dateAtStartOfDay];
    DaySummary * daySum = [DaySummary findOrCreate:@{@"date_day": dayBegin} inContext:self.tripAnalyzerContent];
    daySum.is_analyzed = @NO;
    [daySum addAll_tripsObject:tripSum];
    tripSum.day_summary = daySum;
    
    return daySum;
}

- (WeekSummary*) weekSumForDay:(DaySummary*)daySum
{
    if (nil == daySum) {
        return nil;
    }
    if (daySum.week_summary) {
        return daySum.week_summary;
    }
    
    NSDate * dayBegin = [daySum.date_day dateAtStartOfWeek];
    WeekSummary * weekSum = [WeekSummary findOrCreate:@{@"date_week": dayBegin} inContext:self.tripAnalyzerContent];
    weekSum.is_analyzed = @NO;
    [weekSum addAll_daysObject:daySum];
    daySum.week_summary = weekSum;
    
    return weekSum;
}

- (MonthSummary*) monthSumForDay:(DaySummary*)daySum
{
    if (nil == daySum) {
        return nil;
    }
    if (daySum.month_summary) {
        return daySum.month_summary;
    }
    
    NSDate * dayBegin = [daySum.date_day dateAtStartOfMonth];
    MonthSummary * monthSum = [MonthSummary findOrCreate:@{@"date_month": dayBegin} inContext:self.tripAnalyzerContent];
    monthSum.is_analyzed = @NO;
    [monthSum addAll_daysObject:daySum];
    daySum.month_summary = monthSum;
    
    return monthSum;
}

- (DrivingInfo*) drivingInfoForTrip:(TripSummary*)tripSum
{
    if (nil == tripSum) {
        return nil;
    }
    if (tripSum.driving_info) {
        return tripSum.driving_info;
    }
    
    DrivingInfo * info = [DrivingInfo createInContext:self.tripAnalyzerContent];
    info.trip_owner = tripSum;
    tripSum.driving_info = info;
    
    return info;
}

- (EnvInfo*) environmentForTrip:(TripSummary*)tripSum
{
    if (nil == tripSum) {
        return nil;
    }
    if (tripSum.environment) {
        return tripSum.environment;
    }
    
    EnvInfo * info = [EnvInfo createInContext:self.tripAnalyzerContent];
    info.trip_owner = tripSum;
    tripSum.environment = info;
    
    return info;
}

- (TrafficJam*) allocTrafficInfoForTrip:(TripSummary*)tripSum
{
    if (nil == tripSum) {
        return nil;
    }
    
    TrafficJam * jam = [TrafficJam createInContext:self.tripAnalyzerContent];
    jam.trip_owner = tripSum;
    [tripSum addTraffic_jamsObject:jam];
    
    return jam;
}

- (TurningInfo*) turningInfoForTrip:(TripSummary*)tripSum
{
    if (nil == tripSum) {
        return nil;
    }
    if (tripSum.turning_info) {
        return tripSum.turning_info;
    }
    
    TurningInfo * info = [TurningInfo createInContext:self.tripAnalyzerContent];
    info.trip_owner = tripSum;
    tripSum.turning_info = info;
    
    return info;
}

- (RegionGroup*) startRegionCenter:(CLLocationCoordinate2D)centerFrom toRegionCenter:(CLLocationCoordinate2D)centerTo forTrip:(TripSummary*)tripSum
{
    if (nil == tripSum || !CLLocationCoordinate2DIsValid(centerFrom) || !CLLocationCoordinate2DIsValid(centerTo)) {
        return nil;
    }
    
    BOOL isTemp = (nil == tripSum.end_date);
    ParkingRegion * startRegion = [self addParkingLocation:centerFrom modifyRegionCenter:!tripSum.is_analyzed];
    ParkingRegion * endRegion = nil;
    NSArray * groups = nil;
    if (!isTemp) {
        endRegion = [self addParkingLocation:centerTo modifyRegionCenter:!tripSum.is_analyzed];
        groups = [RegionGroup where:@{@"start_region": startRegion, @"end_region": endRegion, @"is_temp": @NO} inContext:self.tripAnalyzerContent limit:@1];
    } else {
        endRegion = [self tempParkingLocation:centerTo];
        groups = [RegionGroup where:@{@"is_temp": @YES} inContext:self.tripAnalyzerContent limit:@1];
    }
    
    RegionGroup * regionGroup = nil;
    if (groups.count > 0) {
        regionGroup = groups[0];
        regionGroup.start_region = startRegion;
        [startRegion addGroup_owner_stObject:regionGroup];
        regionGroup.end_region = endRegion;
        [endRegion addGroup_owner_edObject:regionGroup];
    } else {
        regionGroup = [RegionGroup create:@{@"start_region": startRegion, @"end_region": endRegion, @"is_temp": @(isTemp)} inContext:self.tripAnalyzerContent];
    }
    
    tripSum.region_group = regionGroup;
    if (!isTemp) {
        [regionGroup addTripsObject:tripSum];
        regionGroup.relative_trips_cnt = @([regionGroup.relative_trips_cnt integerValue]+1);
    }
    
    return regionGroup;
}

- (WeatherInfo*) weatherInfoForTrip:(TripSummary*)tripSum
{
    if (nil == tripSum) {
        return nil;
    }
    if (tripSum.weather) {
        return tripSum.weather;
    }
    
    return nil;
}

@end
