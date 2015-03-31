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

- (void) dropDbAll;

// when login status change
- (void) switchUserDbById:(NSString*)uid;

// merge parking location with device db and user history db, if not exist, request location id from server
- (void) mergeParkingLocation;

// wrapper for subdb

- (TripSummary*) lastTrip;
- (NSDate*) lastTripDateInUserHistory;

- (ParkingRegionDetail*) parkingDetailForCoordinate:(CLLocationCoordinate2D)coordinate minDist:(CGFloat)minDist;
- (NSArray*) tripsWithStartRegion:(ParkingRegion*)region tripLimit:(NSInteger)limit;
- (TripSummary*) bestTripWithStartRegion:(ParkingRegion*)stRegion endRegion:(ParkingRegion*)edRegion;
- (NSArray*) mostUsedParkingRegionLimit:(NSUInteger)limit;

- (DaySummary*) userDaySumForDeviceDaySum:(DaySummary*)daySum;
- (WeekSummary*) userWeekSumForDeviceWeekSum:(WeekSummary*)weekSum;
- (MonthSummary*) userMonthSumForDeviceMonthSum:(MonthSummary*)monthSum;

- (TripSummary*) tripMostDistForMonthSum:(MonthSummary*)monthSum;
- (TripSummary*) tripMostDuringForMonthSum:(MonthSummary*)monthSum;
- (TripSummary*) tripMostJamDuringForMonthSum:(MonthSummary*)monthSum;

@end
