//
//  TripsCoreDataManager.h
//  Location
//
//  Created by taq on 11/5/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CoreDataManager.h"
#import "ObjectiveRecord.h"
#import "TripSummary.h"
#import "DrivingInfo.h"
#import "WeatherInfo.h"
#import "EnvInfo.h"
#import "TrafficJam.h"
#import "TurningInfo.h"
#import "RegionGroup.h"
#import "DaySummary.h"
#import "WeekSummary.h"
#import "ParkingRegionDetail.h"

@interface TripsCoreDataManager : CoreDataManager

// db operation api

- (NSManagedObjectContext *)tripAnalyzerContent;
- (void) dropDb;
- (void) commit;


// analyze info quary api

- (NSArray*) allParkingDetails;

- (TripSummary*) unfinishedTrip;
- (TripSummary*) prevTripBy:(TripSummary*)curTrip;
- (NSArray*) allTrips;
- (NSArray*) unAnalyzedTrips;
- (NSArray*) tripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate;
- (ParkingRegionDetail*) parkingDetailForCoordinate:(CLLocationCoordinate2D)coordinate;
- (NSArray*) mostUsefulTripsLimit:(NSUInteger)limit;
- (NSArray*) tripsWithStartRegion:(ParkingRegion*)region tripLimit:(NSInteger)limit;

- (DaySummary*) daySummaryByDay:(NSDate*)dateDay;
- (WeekSummary*) weekSummaryByDay:(NSDate*)dateWeek;

// analyze info generate api

- (TripSummary*) newTripAt:(NSDate*)beginDate;
- (TripSummary*) newTripAt:(NSDate*)beginDate endAt:(NSDate*)endDate;

- (DaySummary*) daySumForTrip:(TripSummary*)tripSum;
- (WeekSummary*) weekSumForDay:(DaySummary*)daySum;

- (DrivingInfo*) drivingInfoForTrip:(TripSummary*)tripSum;
- (EnvInfo*) environmentForTrip:(TripSummary*)tripSum;
- (TurningInfo*) turningInfoForTrip:(TripSummary*)tripSum;
- (TrafficJam*) allocTrafficInfoForTrip:(TripSummary*)tripSum;

- (RegionGroup*) startRegionCenter:(CLLocationCoordinate2D)centerFrom toRegionCenter:(CLLocationCoordinate2D)centerTo forTrip:(TripSummary*)tripSum;
- (WeatherInfo*) weatherInfoForTrip:(TripSummary*)tripSum;

@end
