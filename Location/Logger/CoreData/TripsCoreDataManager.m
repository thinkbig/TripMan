//
//  TripsCoreDataManager.m
//  Location
//
//  Created by taq on 11/5/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripsCoreDataManager.h"
#import "NSManagedObject+ActiveRecord.h"

@interface TripsCoreDataManager ()

@property (nonatomic, strong) NSManagedObjectContext *          tripAnalyzerContent;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void) dropDb
{
    NSURL *databaseDir = [self.applicationDocumentsDirectory URLByAppendingPathComponent:[self databaseName]];
    [[[NSFileManager alloc] init] removeItemAtURL:databaseDir error:nil];
}

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
                DDLogWarn(@"Core Data commit fail: %@", err);
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
        if ([detail.region containsCoordinate:coordinate]) {
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
        regionGroupArr = [RegionGroup where:@"is_temp == NO" order:@{@"relative_trips_cnt": @"DESC"} limit:@(limit)];
    } else {
        regionGroupArr = [RegionGroup where:@"is_temp == NO" order:@{@"relative_trips_cnt": @"DESC"}];
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

- (NSArray*) tripsWithStartRegion:(ParkingRegion*)region tripLimit:(NSInteger)limit
{
    NSArray * allGroups = [region.group_owner_st allObjects];
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
    
    return newTrip;
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
