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
#define REGION_ID_MOST_PARKING(num_)       [NSString stringWithFormat:@"idPark%ld", (num_)]

#define REGION_GROUP_LAST_STILL            @"groupStill"
#define REGION_GROUP_LAST_PARKING          @"groupPark"
#define REGION_GROUP_MOST_STAY             @"groupMost"


@interface LocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *   locationManager;

- (void)setKeepMonitor;
- (void)startLocationTracking;

- (void)setParkingLocation:(CLLocation*)loc;

- (void)startMotionChecker;
- (void)stopMotionChecker;
- (NSTimeInterval) duringForWalkRunWithin:(NSTimeInterval)within;
- (NSTimeInterval) duringForAutomationWithin:(NSTimeInterval)within;

- (void) test;

@end
