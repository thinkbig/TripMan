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
#import "MonthSummary.h"
#import "ParkingRegionDetail.h"

@interface TripsCoreDataManager : CoreDataManager

@property (nonatomic, strong) NSString *        dbNamePrefix;            // seperate sqlite file name;
@property (nonatomic, strong) NSManagedObjectContext *          tripAnalyzerContent;

// db operation api

- (BOOL) dbExist;
- (void) dropDb;
- (void) commit;

- (dispatch_queue_t) readQueue;

// analyze info quary api

- (NSArray*) allParkingDetails;

// trip data for report
- (NSArray*) parkingRegionsToReport:(BOOL)forceAll;
- (NSArray*) tripsReadyToReport:(BOOL)forceAll;
- (NSArray*) tripRawsReadyToReport;

// trips for display
- (TripSummary*) unfinishedTrip;
- (TripSummary*) prevTripByDate:(NSDate*)date;
- (TripSummary*) lastTrip;
- (NSArray*) allTrips;
- (NSArray*) unAnalyzedTrips;
- (NSArray*) allFinishedTrips;
- (NSArray*) tripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate;
- (NSArray*) mostUsefulTripsLimit:(NSUInteger)limit;

- (ParkingRegionDetail*) parkingDetailForCoordinate:(CLLocationCoordinate2D)coordinate minDist:(CGFloat)minDist;
- (ParkingRegion*) parkingRegioinForId:(NSString*)parkingId;
- (NSArray*) mostUsedParkingRegionLimit:(NSUInteger)limit;

- (DaySummary*) daySummaryByDay:(NSDate*)dateDay;
- (WeekSummary*) weekSummaryByDay:(NSDate*)dateDay;
- (MonthSummary*) monthSummaryByDay:(NSDate*)dateDay;

// analyze info generate api

- (TripSummary*) newTripAt:(NSDate*)beginDate;
- (TripSummary*) newTripAt:(NSDate*)beginDate endAt:(NSDate*)endDate;

- (DaySummary*) daySumForTrip:(TripSummary*)tripSum;
- (WeekSummary*) weekSumForDay:(DaySummary*)daySum;
- (MonthSummary*) monthSumForDay:(DaySummary*)daySum;

- (DrivingInfo*) drivingInfoForTrip:(TripSummary*)tripSum;
- (EnvInfo*) environmentForTrip:(TripSummary*)tripSum;
- (TurningInfo*) turningInfoForTrip:(TripSummary*)tripSum;
- (TrafficJam*) allocTrafficInfoForTrip:(TripSummary*)tripSum;

- (RegionGroup*) startRegionCenter:(CLLocationCoordinate2D)centerFrom toRegionCenter:(CLLocationCoordinate2D)centerTo forTrip:(TripSummary*)tripSum;
- (WeatherInfo*) weatherInfoForTrip:(TripSummary*)tripSum;

// method for debug
- (void) recoverDeletedLocation;

@end
