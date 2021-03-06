//
//  AnaDbManager.h
//  TripMan
//
//  Created by taq on 1/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TripsCoreDataManager.h"

@interface AnaDbManager : NSObject

+ (instancetype) sharedInst;
+ (TripsCoreDataManager *) deviceDb;
+ (TripsCoreDataManager *) userDb;

- (void) commit;

- (void) dropDbAll;

// when login status change
- (void) switchUserDbById:(NSString*)uid;

// merge parking location with device db and user history db, if not exist, request location id from server
- (void) mergeParkingLocation;

// wrapper for subdb

- (TripSummary*) lastTrip;
- (NSDate*) lastTripDateInUserHistory;

- (ParkingRegionDetail*) parkingDetailForCoordinate:(CLLocationCoordinate2D)coordinate minDist:(CGFloat)minDist;
- (ParkingRegion*) parkingRegioinForId:(NSString*)parkingId;
- (NSArray*) mostUsedParkingRegionLimit:(NSUInteger)limit;

- (NSArray*) tripsWithStartRegion:(ParkingRegion*)region tripLimit:(NSInteger)limit startDate:(NSDate*)stDate;
- (TripSummary*) bestTripWithStartRegion:(ParkingRegion*)stRegion endRegion:(ParkingRegion*)edRegion startDate:(NSDate*)stDate;

- (DaySummary*) userDaySumForDeviceDaySum:(DaySummary*)daySum;
- (WeekSummary*) userWeekSumForDeviceWeekSum:(WeekSummary*)weekSum;
- (MonthSummary*) userMonthSumForDeviceMonthSum:(MonthSummary*)monthSum;

- (TripSummary*) tripMostDistForMonthSum:(MonthSummary*)monthSum;
- (TripSummary*) tripMostDuringForMonthSum:(MonthSummary*)monthSum;
- (TripSummary*) tripMostJamDuringForMonthSum:(MonthSummary*)monthSum;

// method for debug
- (void) recoverDeletedLocation;


@end
