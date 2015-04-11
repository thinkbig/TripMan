//
//  LocationTracker.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#define REGION_ID_LAST_STILL               @"idStill"
#define REGION_ID_LAST_PARKING             @"idPark"
#define REGION_ID_MOST_PARKING(num_)       [NSString stringWithFormat:@"idPark%ld", (long)(num_)]

#define REGION_GROUP_LAST_STILL            @"groupStill"
#define REGION_GROUP_LAST_PARKING          @"groupPark"
#define REGION_GROUP_MOST_STAY             @"groupMost"

#define kGoodHorizontalAccuracy          90
#define kLowHorizontalAccuracy             160
#define kPoorHorizontalAccuracy            210

typedef NS_ENUM(NSUInteger, eGPSSignalStrength) {
    eGPSSignalStrengthUnknow = 0,       // default
    eGPSSignalStrengthInvalid,          // accu < 0
    eGPSSignalStrengthPoor,             // > kPoorHorizontalAccuracy
    eGPSSignalStrengthWeak,             // kLowHorizontalAccuracy ~ kPoorHorizontalAccuracy
    eGPSSignalStrengthGood,             // kGoodHorizontalAccuracy ~ kLowHorizontalAccuracy
    eGPSSignalStrengthStrong,           // < kGoodHorizontalAccuracy
};

@interface LocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *           locationManager;
@property (nonatomic, strong) CMMotionActivity *            rawMotionActivity;
@property (nonatomic) eGPSSignalStrength                    signalStrength;
@property (nonatomic) BOOL                                  useSignificantLocationChange;

- (void)startLocationTracking;
- (void)updateCurrentLocation;

- (void)setParkingLocation:(CLLocation*)loc;

- (void)startMotionChecker;
- (void)stopMotionChecker;
- (NSTimeInterval) duringForWalkRunWithin:(NSTimeInterval)within;
- (NSTimeInterval) duringForAutomationWithin:(NSTimeInterval)within;

@end
