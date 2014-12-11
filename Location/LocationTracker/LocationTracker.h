//
//  LocationTracker.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define REGION_ID_LAST_STILL               @"idStill"
#define REGION_ID_LAST_PARKING             @"idPark"

#define REGION_GROUP_LAST_STILL            @"groupStill"
#define REGION_GROUP_LAST_PARKING          @"groupPark"


@interface LocationTracker : NSObject <CLLocationManagerDelegate>

+ (CLLocationManager *)sharedLocationManager;

- (void)setKeepMonitor;
- (void)startLocationTracking;
- (void)stopLocationTracking;

- (void)setParkingLocation:(CLLocation*)loc;

- (void)startMotionChecker;
- (void)stopMotionChecker;
- (NSTimeInterval) duringForWalkRunWithin:(NSTimeInterval)within;
- (NSTimeInterval) duringForAutomationWithin:(NSTimeInterval)within;

@end
