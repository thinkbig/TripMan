//
//  LocationTracker.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location All rights reserved.
//

#import "LocationTracker.h"
#import "AppDelegate.h"
#import "GPSAnalyzerRealTime.h"
#import "GPSOffTimeFilter.h"
#import <Parse/Parse.h>
#import "TSPair.h"
#import "AnaDbManager.h"

#define kLocationUpdateInterval         11
#define kLocationUpdateLongInterval     20

#define kWakeUpBySystem             @"kWakeUpBySystem"
#define kLocationAccu               kCLLocationAccuracyBest
#define kLocationAccuNotDriving     kCLLocationAccuracyBest
#define kLocationDistFilter         kCLDistanceFilterNone

typedef enum
{
    MotionTypeNotMoving = 0,
    MotionTypeWalking,
    MotionTypeRunning,
    MotionTypeAutomotive
} LTMotionType;

@interface LocationTracker ()
{
    CLCircularRegion *            _lastParkingRegion;
    CLCircularRegion *            _lastStillRegion;
    BOOL                          _keepMonitoring;
    BOOL                          _shortUpdate;
    
    NSDate *                      _lastStationaryDate;
    
    NSInteger                     _recordCnt;
    
    BOOL                          _locationStarted;
    BOOL                          _setShoudlStop;
    BOOL                          _isDriving;
    
    CLLocation *                  _lastLastLoc;
    CLLocation *                  _lastLoc;
    
    NSDate *                      _resumeGpsDate;      // each time call start location update, use to check if the gps is warn up
    NSDate *                      _maylostGpsDate;     // the date not getting good gps
    NSDate *                      _lastStopGpsDate;
}

@property (nonatomic, strong) CMAccelerometerData *         lastAcceleraion;

@property (nonatomic) LTMotionType                          eCurrentMotion;
@property (nonatomic, strong) NSMutableArray *              motionArray;
@property (nonatomic) BOOL                                  isDetectMotion;

@property (nonatomic, strong) NSTimer *                     restartTimer;
@property (nonatomic) BOOL                                  isDriving;
@property (nonatomic, strong) NSMutableDictionary *         regionExitRecorder;

@end

@implementation LocationTracker

- (CLLocationManager *)locationManager
{
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kLocationAccu;
        _locationManager.distanceFilter = kLocationDistFilter;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    return _locationManager;
}

+ (CMMotionManager *)sharedMotionManager {
	static CMMotionManager *_motionManager;
	@synchronized(self) {
		if (_motionManager == nil) {
			_motionManager = [[CMMotionManager alloc] init];
            _motionManager.accelerometerUpdateInterval = 1.0;
            //_motionManager.gyroUpdateInterval = 0.2;
		}
	}
	return _motionManager;
}

+ (CMMotionActivityManager *)sharedMotionActivityManager {
	static CMMotionActivityManager *_motionActivityManager;
	@synchronized(self) {
		if (_motionActivityManager == nil) {
			_motionActivityManager = [[CMMotionActivityManager alloc] init];
		}
	}
	return _motionActivityManager;
}

- (id)init
{
    self = [super init];
	if (self)
    {
        _shortUpdate = NO;
        self.signalStrength = eGPSSignalStrengthUnknow;
        _locationStarted = NO;
        self.regionExitRecorder = [NSMutableDictionary dictionaryWithCapacity:2];
        [self preload];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tripStatChange:) name:kNotifyTripStatChange object:nil];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSignificantMonitor) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentLocation) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
	return self;
}

- (NSTimeInterval) duringForAutomationWithin:(NSTimeInterval)within
{
    if (self.motionArray.count == 0) {
        return -1;
    }
    TSPair * lastPair = self.motionArray[0];
    NSDate * toDate = [NSDate date];
    NSDate * fromDate = [toDate dateByAddingTimeInterval:-within];
    if ([fromDate compare:lastPair.first] == NSOrderedAscending) {
        return -1;
    }
    
    __block NSTimeInterval during = 0;
    __block NSDate * lastDate = toDate;
    NSArray * copyArr = [NSArray arrayWithArray:_motionArray];
    [copyArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TSPair * obj, NSUInteger idx, BOOL *stop) {
        if ([fromDate compare:obj.first] == NSOrderedAscending) {
            if (MotionTypeAutomotive == (LTMotionType)[obj.second integerValue]) {
                during += [lastDate timeIntervalSinceDate:obj.first];
            }
        } else {
            if (MotionTypeAutomotive == (LTMotionType)[obj.second integerValue]) {
                during += [lastDate timeIntervalSinceDate:fromDate];
            }
            *stop = YES;
        }
        lastDate = obj.first;
    }];

    return during;
}

- (NSTimeInterval) duringForWalkRunWithin:(NSTimeInterval)within
{
    if (self.motionArray.count == 0) {
        return -1;
    }
    TSPair * lastPair = self.motionArray[0];
    NSDate * toDate = [NSDate date];
    NSDate * fromDate = [toDate dateByAddingTimeInterval:-within];
    if ([fromDate compare:lastPair.first] == NSOrderedAscending) {
        return -1;
    }
    
    __block NSTimeInterval during = 0;
    __block NSDate * lastDate = toDate;
    NSArray * copyArr = [NSArray arrayWithArray:_motionArray];
    [copyArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TSPair * obj, NSUInteger idx, BOOL *stop) {
        if ([fromDate compare:obj.first] == NSOrderedAscending) {
            if (MotionTypeWalking == (LTMotionType)[obj.second integerValue] || MotionTypeRunning == (LTMotionType)[obj.second integerValue]) {
                during += [lastDate timeIntervalSinceDate:obj.first];
            }
        } else {
            if (MotionTypeWalking == (LTMotionType)[obj.second integerValue] || MotionTypeRunning == (LTMotionType)[obj.second integerValue]) {
                during += [lastDate timeIntervalSinceDate:fromDate];
            }
            *stop = YES;
        }
        lastDate = obj.first;
    }];
    
    return during;
}

- (void)stopMotionChecker
{
    self.isDetectMotion = NO;
    if ([CMMotionActivityManager isActivityAvailable]) {
        CMMotionActivityManager * activityManager = [LocationTracker sharedMotionActivityManager];
        [activityManager stopActivityUpdates];
    }
}

- (void)startMotionChecker
{
    if (self.isDetectMotion) {
        return;
    }
    self.motionArray = [NSMutableArray array];
    self.eCurrentMotion = MotionTypeNotMoving;
    if ([CMMotionActivityManager isActivityAvailable]) {
        self.isDetectMotion = YES;
        CMMotionActivityManager * activityManager = [LocationTracker sharedMotionActivityManager];
        [activityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMotionActivity *activity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rawMotionActivity = activity;
                LTMotionType type = MotionTypeNotMoving;
                if (activity.walking) {
                    type = MotionTypeWalking;
                } else if (activity.running) {
                    type = MotionTypeRunning;
                } else if (activity.automotive && activity.confidence > CMMotionActivityConfidenceLow) {
                    type = MotionTypeAutomotive;
                } else if (activity.stationary || activity.unknown) {
                    type = MotionTypeNotMoving;
                }
                
                if (type != self.eCurrentMotion) {
                    [self.motionArray addObject:TSPairMake([NSDate date], @(type), nil)];
                    self.eCurrentMotion = type;
                }
            });
        }];
    }
}

- (void) startAcceleratorChecker
{
    CMMotionManager *motionManager = [LocationTracker sharedMotionManager];
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                            if(error){
                                                DDLogWarn(@"CMMotionManager error: %@", error);
                                            } else {
                                                self.lastAcceleraion = accelerometerData;
                                            }
                                        }];
}

- (void)setKeepMonitor
{
    _shortUpdate = NO;
    _maylostGpsDate = nil;
    _resumeGpsDate = nil;
    _setShoudlStop = NO;
    _keepMonitoring = YES;
    _lastStationaryDate = nil;
    _recordCnt = 20;
}

- (void)preload
{
    CLLocationManager * manager = self.locationManager;
    NSSet * regions = manager.monitoredRegions;
    NSString * stillId = [self regionId:REGION_ID_LAST_STILL withGroup:REGION_GROUP_LAST_STILL];
    NSString * parkingId = [self regionId:REGION_ID_LAST_PARKING withGroup:REGION_GROUP_LAST_PARKING];
    for (CLCircularRegion * region in regions) {
        if ([stillId isEqualToString:region.identifier]) {
            _lastStillRegion = region;
        } else if ([parkingId isEqualToString:region.identifier]) {
            _lastParkingRegion = region;
        }
    }
}

- (NSString*)regionId:(NSString*)rawId withGroup:(NSString*)group
{
    return [NSString stringWithFormat:@"%@|%@", group, rawId];
}

- (void)tripStatChange:(NSNotification *)notification
{
    NSNumber * inTrip = notification.userInfo[@"inTrip"];
    NSNumber * dropTrip = notification.userInfo[@"dropTrip"];
    if (inTrip)
    {
        NSDate * statDate = notification.userInfo[@"date"];
        if (nil == statDate) {
            statDate = [NSDate date];
        }
        NSNumber * lat = notification.userInfo[@"lat"];
        NSNumber * lon = notification.userInfo[@"lon"];
        CLCircularRegion* theRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]) radius:cReagionRadius identifier:@"tripStEd"];
        if ([inTrip boolValue]) {
            if (!DEBUG_MODE) {
                GPSEvent5(statDate, eGPSEventDriveStart, theRegion, @"tripStEd", nil);
            }
            // remove all monitor spot (no not remove, in case crash)
//            CLLocationManager * manager = self.locationManager;
//            NSSet * regions = manager.monitoredRegions;
//            for (CLCircularRegion * region in regions) {
//                [manager stopMonitoringForRegion:region];
//            }
        } else {
            if (!DEBUG_MODE) {
                if (dropTrip && [dropTrip boolValue]) {
                    GPSEvent5(statDate, eGPSEventDriveIgnore, theRegion, @"tripStEd", nil);
                } else {
                    GPSEvent5(statDate, eGPSEventDriveEnd, theRegion, @"tripStEd", nil);
                }
            }
            if (lat && lon) {
                CLLocation * stopLoc = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
                [self setParkingLocation:stopLoc];
            }
        }
    }
}

- (void)startLocationTracking
{
    DDLogWarn(@"startLocationTracking");
    
    if (!IS_UPDATING) {
        [self setKeepMonitor];
        [self startAcceleratorChecker];
        [self startMotionChecker];
        [self runBackgroundTask:1];
    }
}

- (void)updateCurrentLocation
{
    if (!IS_UPDATING && !_keepMonitoring && !_isDriving) {
        NSNumber * wakeupBySys = [[NSUserDefaults standardUserDefaults] objectForKey:kWakeUpBySystem];
        if (nil == wakeupBySys || [wakeupBySys boolValue]) {
            DDLogWarn(@"updateCurrentLocation");
            _shortUpdate = YES;
            _setShoudlStop = NO;
            [self runBackgroundTask:1];
        }
    }
}

- (void)realStop
{
    [self.restartTimer invalidate];
    self.restartTimer = nil;
    
    if (_setShoudlStop) {
        return;
    }
    _shortUpdate = NO;
    _maylostGpsDate = nil;
    _keepMonitoring = NO;
    _resumeGpsDate = nil;
    self.signalStrength = eGPSSignalStrengthUnknow;
    _setShoudlStop = YES;
    _lastLoc = _lastLastLoc = nil;
    
    CLLocation * lastGoodGPS = [BussinessDataProvider lastGoodLocation];
    if (lastGoodGPS) {
        [self setStillLocation:lastGoodGPS force:YES];
    }
    
    CMMotionManager *motionManager = [LocationTracker sharedMotionManager];
    [motionManager stopAccelerometerUpdates];
    [self stopMotionChecker];
    
    CLLocationManager *locationManager = self.locationManager;
    [locationManager stopUpdatingLocation];
    if (!self.useSignificantLocationChange) {
        [locationManager stopMonitoringSignificantLocationChanges];
    }
    _lastStopGpsDate = [NSDate date];
    
    DDLogWarn(@"realStopLocationTracking");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kWakeUpBySystem];
        [[NSUserDefaults standardUserDefaults] synchronize];
        DDLogWarn(@"real reset kWakeUpBySystem flag");
    });
    
    GPSEvent([NSDate date], eGPSEventStopGPS);
}

- (BOOL)registerNotificationForLocation:(CLLocation *)myLocation withRadius:(NSNumber *)myRadius assignIdentifier:(NSString *)identifier group:(NSString*)groupName
{
    // Do not create regions if support is unavailable or disabled.
    if ( ![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        DDLogWarn(@"&&&&&&&&&&&&&& isMonitoringAvailableForClass = NO");
        self.useSignificantLocationChange = YES;
        return NO;
    }
    
    // If the radius is too large, registration fails automatically,
    // so clamp the radius to the max value.
    CLLocationManager *locationManager = self.locationManager;
    CLLocationDistance theRadius = [myRadius doubleValue];
    if (theRadius > locationManager.maximumRegionMonitoringDistance) {
        theRadius = locationManager.maximumRegionMonitoringDistance;
    }
    
    CLLocationCoordinate2D theCoordinate = myLocation.coordinate;
    
    // Create the region and start monitoring it.
    
    identifier = identifier.length > 0 ? identifier : @"DefaultReagionId";
    groupName = groupName.length > 0 ? groupName : @"DefaultReagionGroup";
    
    CLCircularRegion* theRegion = [[CLCircularRegion alloc] initWithCenter:theCoordinate radius:theRadius identifier:[self regionId:identifier withGroup:groupName]];
    [locationManager startMonitoringForRegion:theRegion];
    GPSEvent5([NSDate date], eGPSEventMonitorRegion, theRegion, groupName, nil);
    
    if ([groupName isEqualToString:REGION_GROUP_LAST_STILL]) {
        _lastStillRegion = theRegion;
    } else if ([groupName isEqualToString:REGION_GROUP_LAST_PARKING]) {
        _lastParkingRegion = theRegion;
    }
    
    return YES;
}

- (void)recordEvent:(eGPSEvent)event forReagion:(CLCircularRegion *)region
{
    NSArray * reagionIds = [region.identifier componentsSeparatedByString:@"|"];
    if (reagionIds.count > 1) {
        GPSEvent5([NSDate date], event, region, reagionIds[0], nil);
    }
}


- (void)runBackgroundTask: (int)time
{
    [self.restartTimer invalidate];
    
    //check if application is in background mode
    UIApplication * app = [UIApplication sharedApplication];
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if (app.applicationState == UIApplicationStateBackground) {
        if (kCLAuthorizationStatusAuthorizedAlways != authorizationStatus) {
            return;
        }
        //create UIBackgroundTaskIdentifier and create tackground task, which starts after time
        __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        self.restartTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(__realStartLocation) userInfo:nil repeats:NO];
    } else {
        if (kCLAuthorizationStatusNotDetermined == authorizationStatus) {
            CLLocationManager *locationManager = self.locationManager;
            if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                // ios 8
                [locationManager requestAlwaysAuthorization];
            } else {
                self.restartTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(__realStartLocation) userInfo:nil repeats:NO];
            }
        } else {
            self.restartTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(__realStartLocation) userInfo:nil repeats:NO];
        }
    }
}

- (void) __realStartLocation
{
    NSLog(@"&&&&&&&&&&&&&&&&&&&&&& start &&&&&&&&&&&&&&&&&&&&&&");
    
    _resumeGpsDate = nil;
    CLLocationManager *locationManager = self.locationManager;
    locationManager.desiredAccuracy = self.isDriving ? kLocationAccu : kLocationAccuNotDriving;
    [locationManager startUpdatingLocation];
    [locationManager startMonitoringSignificantLocationChanges];
    
}

- (void) __realPauseLocationWithRestartDuring:(NSTimeInterval)restartIntval
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"&&&&&&&&&&&&&&&&&&&&&& stop &&&&&&&&&&&&&&&&&&&&&&");
        CLLocationManager *locationManager = self.locationManager;
        [locationManager stopUpdatingLocation];
        //[locationManager stopMonitoringSignificantLocationChanges];
        if (!_setShoudlStop) {
            [self runBackgroundTask:restartIntval];
        }
    });
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status > kCLAuthorizationStatusDenied) {
        [self runBackgroundTask:1];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kLocationAuthrizeStatChange" object:nil];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLCircularRegion *)region
{
    DDLogWarn(@"locationManager didEnterRegion: %@ (%f)", region.identifier, region.radius);
    
    [self recordEvent:eGPSEventEnterRegion forReagion:region];
    
    if (!self.isDriving && [region.identifier hasSuffix:REGION_GROUP_MOST_STAY]) {
        [self runBackgroundTask:1];
    }
    
    if (_isDriving) {
        [self.regionExitRecorder removeAllObjects];
    } else {
        NSInteger exitCnt = [self.regionExitRecorder[region.identifier] integerValue];
        if (exitCnt > 0) {
            float theRadius = region.radius + 50;
            if (theRadius < 500) {
                CLLocationManager *locationManager = self.locationManager;
                CLCircularRegion* theRegion = [[CLCircularRegion alloc] initWithCenter:region.center radius:theRadius identifier:region.identifier];
                [locationManager startMonitoringForRegion:theRegion];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLCircularRegion *)region
{
    DDLogWarn(@"locationManager didExitRegion: %@ (%f)", region.identifier, region.radius);
    
    [self recordEvent:eGPSEventExitRegion forReagion:region];
    
    if (_isDriving) {
        [self.regionExitRecorder removeAllObjects];
    } else {
        NSInteger exitCnt = [self.regionExitRecorder[region.identifier] integerValue];
        self.regionExitRecorder[region.identifier] = @(exitCnt+1);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyExitReagion object:nil userInfo:@{@"date":[NSDate date]}];
    
    [self setKeepMonitor];
    [self runBackgroundTask:1];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLCircularRegion *)region withError:(NSError *)error
{
    DDLogWarn(@"locationManager monitoringDidFailForRegion");
    [self recordEvent:eGPSEventMonitorFail forReagion:region];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    DDLogWarn(@"------------- DeferredLocationUpdates End %@ -------------- ", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"locationManager didUpdateLocations");
    
    _isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
    if (_keepMonitoring || _isDriving) {
        _lastStopGpsDate = nil;
    }
    if (_lastStopGpsDate && [[NSDate date] timeIntervalSinceDate:_lastStopGpsDate] < 5) {
        DDLogWarn(@"ignore location since we just close the gps sensor");
        return;
    } else {
        _lastStopGpsDate = nil;
    }
    
    NSNumber * wakeupBySys = [[NSUserDefaults standardUserDefaults] objectForKey:kWakeUpBySystem];
    if (!_shortUpdate && (nil == wakeupBySys || [wakeupBySys boolValue])) {
        [self setKeepMonitor];
        [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:kWakeUpBySystem];
        [self startLocationTracking];
    }
    
    CLLocationAccuracy mostAccuracy = MAXFLOAT;
    CLLocation * mostAccuracyLocation = nil;
    CGFloat calSpeed = -1;
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 60.0) {
            if (i == locations.count-1) {
                return;
            }
            continue;
        }
        
        if (_lastLoc && [newLocation.timestamp timeIntervalSinceDate:_lastLoc.timestamp] < 1) {
            if (i == locations.count-1) {
                return;
            }
            // 说明是重复点，忽略
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil && theAccuracy>0 && theAccuracy<420 && (!(theLocation.latitude==0.0 && theLocation.longitude==0.0)))
        {
            BOOL isMost = NO;
            if (mostAccuracy > theAccuracy) {
                mostAccuracy = theAccuracy;
                mostAccuracyLocation = newLocation;
                calSpeed = mostAccuracyLocation.speed;
                isMost = YES;
            }
            
            CGFloat speed = newLocation.speed;
//            NSTimeInterval interval = 0;
//            if (speed < 0 && _lastLoc) {
//                interval = [newLocation.timestamp timeIntervalSinceDate:_lastLoc.timestamp];
//                CGFloat dist = [newLocation distanceFromLocation:_lastLoc];
//                if (interval > 3 && ((newLocation.horizontalAccuracy < kPoorHorizontalAccuracy && _lastLoc.horizontalAccuracy < kPoorHorizontalAccuracy) || dist > 50)) {
//                    // if the gps signal is too low, we can not cal the speed
//                    CGFloat tmpSpeed = dist/interval;
//                    if (tmpSpeed < cAvgNoiceSpeed) {
//                        if (!_isDriving) {
//                            BOOL skipModify = NO;
//                            if (newLocation.horizontalAccuracy > kPoorHorizontalAccuracy && _lastLoc.horizontalAccuracy > kPoorHorizontalAccuracy) {
//                                skipModify = YES;
//                            }
//                            CGFloat angleThres = 100;
//                            if (tmpSpeed > cAvgDrivingSpeed*2) {
//                                if (newLocation.horizontalAccuracy > kLowHorizontalAccuracy || _lastLoc.horizontalAccuracy > kLowHorizontalAccuracy) {
//                                    angleThres = 50;
//                                }
//                            }
//                            if (!skipModify && _lastLastLoc) {
//                                CGFloat angle = [GPSOffTimeFilter checkPointAngle:[GPSOffTimeFilter coor2Point:_lastLastLoc.coordinate] antPt:[GPSOffTimeFilter coor2Point:_lastLoc.coordinate] antPt:[GPSOffTimeFilter coor2Point:newLocation.coordinate]];
//                                if (angle < angleThres) {
//                                    // filter the wrong gps
//                                    speed = tmpSpeed;
//                                }
//                            }
//                        } else {
//                            if (interval < 5 || tmpSpeed > cAvgDrivingSpeed*6) {
//                                tmpSpeed = MIN(tmpSpeed/2.0, cAvgDrivingSpeed*6.1);
//                            }
//                            speed = tmpSpeed;
//                        }
//                        if (isMost) {
//                            calSpeed = speed;
//                        }
//                    }
//                }
//            }
            
            _lastLastLoc = _lastLoc;
            _lastLoc = newLocation;
            
            GPSLog2(newLocation, self.lastAcceleraion, speed);
            //DDLogWarn(@"location is: <%f, %f>, speed=%f, accuracy=%f, origSpeed=%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude, speed, newLocation.horizontalAccuracy, newLocation.speed);
        }
    }
    
    if (nil == mostAccuracyLocation)
    {
        BOOL didLostGps = NO;
        if (nil == _maylostGpsDate) {
            _maylostGpsDate = [NSDate date];
        } else {
            NSTimeInterval lostGpsDuring = [[NSDate date] timeIntervalSinceDate:_maylostGpsDate];
            if ((_isDriving && lostGpsDuring > 20 * 60) || (!_isDriving && lostGpsDuring > 5 * 60)) {
                didLostGps = YES;
            }
        }
        CLLocation * badLoc = nil;
        if (locations.count > 0) {
            badLoc = [locations lastObject];
        }
        DDLogWarn(@"good location is not valid, keep start, <%f,%f>, accu=%f", badLoc.coordinate.latitude, badLoc.coordinate.longitude, badLoc.horizontalAccuracy);
        self.signalStrength = eGPSSignalStrengthInvalid;
        if (didLostGps) {
            DDLogWarn(@"didLostGps ###########");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyGpsLost object:nil];
                [self realStop];
            });
        } else {
            UIApplication * app = [UIApplication sharedApplication];
            if (app.applicationState != UIApplicationStateActive) {
                NSTimeInterval backgroundRemain = [UIApplication sharedApplication].backgroundTimeRemaining;
                if (backgroundRemain > 0 && backgroundRemain < 20) {
                    DDLogWarn(@"backgroundRemain is low %f", backgroundRemain);
                    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
                        [app endBackgroundTask:bgTask];
                        bgTask = UIBackgroundTaskInvalid;
                    }];
                }
            }
        }
        return;
    } else {
        _maylostGpsDate = nil;
        if (self.locationManager.monitoredRegions.count == 0) {
            [self registerNotificationForLocation:mostAccuracyLocation withRadius:@(cReagionRadius) assignIdentifier:REGION_ID_LAST_STILL group:REGION_GROUP_LAST_STILL];
        }
    }
    
    if (nil == _resumeGpsDate) {
        _resumeGpsDate = mostAccuracyLocation.timestamp;
    }
    
    if (mostAccuracyLocation.horizontalAccuracy > kPoorHorizontalAccuracy) {
        self.signalStrength = eGPSSignalStrengthPoor;
    } else if (mostAccuracyLocation.horizontalAccuracy > kLowHorizontalAccuracy) {
        self.signalStrength = eGPSSignalStrengthWeak;
    } else if (mostAccuracyLocation.horizontalAccuracy > kGoodHorizontalAccuracy) {
        self.signalStrength = eGPSSignalStrengthGood;
    } else if (mostAccuracyLocation.horizontalAccuracy > 0) {
        self.signalStrength = eGPSSignalStrengthStrong;
    }

    BOOL isWarming = (mostAccuracyLocation.speed < 0 && self.signalStrength <= eGPSSignalStrengthWeak && [mostAccuracyLocation.timestamp timeIntervalSinceDate:_resumeGpsDate] < 4);
    if (self.isDriving != _isDriving) {
        DDLogWarn(@"drive stat change to: %d", _isDriving);
        self.isDriving = _isDriving;
        _recordCnt = 20;
    }
    
    if (!_isDriving)
    {
        if (_keepMonitoring) {
            if (calSpeed > cInsTrafficJamSpeed || isWarming) {
                // already driving OR the gps is warming
                _lastStationaryDate = nil;
            }
            if (_lastStationaryDate && [mostAccuracyLocation.timestamp timeIntervalSinceDate:_lastStationaryDate] > cCanStopMonitoringThreshold) {
                NSTimeInterval timeGap = [mostAccuracyLocation.timestamp timeIntervalSinceDate:_lastStationaryDate];
                eMoveStat moveStat = [GPSLogger sharedLogger].gpsAnalyzer.moveStat;
                if (eMoveStatLine == moveStat) {
                    if (timeGap > cCanStopMonitoringThreshold*2) {
                        _keepMonitoring = NO;
                    }
                } else if (timeGap > cCanStopMonitoringThreshold) {
                    _keepMonitoring = NO;
                }
            }
            if (nil == _lastStationaryDate && calSpeed < cInsWalkingSpeed) {
                _lastStationaryDate = mostAccuracyLocation.timestamp;
            }
            [self startMotionChecker];
            if ([self duringForAutomationWithin:20] > 8) {
                DDLogWarn(@"&&&&&&&&&&&&& motion regard as drive start &&&&&&&&&&&&& ");
                _keepMonitoring = YES;
            }
            else if ([self duringForWalkRunWithin:40] > 8 || 0 == [self duringForAutomationWithin:cCanStopMonitoringThreshold]) {
                // 如果开车时，正在使用或者路况不好造成颠簸，会误判断为走路，因此删除该逻辑
                DDLogWarn(@"&&&&&&&&&&&&& motion regard as walking, stop monitor &&&&&&&&&&&&& ");
                //_keepMonitoring = NO;
            }
        }
        
        if (!_keepMonitoring || _shortUpdate) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self realStop];
            });
        }
    } else {
        _keepMonitoring = NO;
        _lastStationaryDate = nil;
    }
    
    if (![wakeupBySys boolValue] && mostAccuracyLocation && !isWarming) {
        NSTimeInterval interval = kLocationUpdateLongInterval;
        if (calSpeed > cInsDrivingSpeed || _isDriving) {
            interval = kLocationUpdateInterval;
        }
        if (_isDriving) {
            [self __realPauseLocationWithRestartDuring:interval];
        } else {
            if (_keepMonitoring) {
                [self __realPauseLocationWithRestartDuring:interval];
            }
        }
    }
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
    DDLogWarn(@"locationManager error:%@",error);
    GPSEvent3([NSDate date], eGPSEventGPSFail, error.localizedDescription);
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            DDLogWarn(@"locationManager kCLErrorNetwork");
        }
            break;
        case kCLErrorDenied:{
            DDLogWarn(@"locationManager kCLErrorDenied");
        }
            break;
        default:
        {
            
        }
            break;
    }
}

- (void)setStillLocation:(CLLocation*)loc force:(BOOL)forceSet
{
    BOOL result = YES;
    if (forceSet || (loc && CLLocationCoordinate2DIsValid(loc.coordinate) && loc.speed <= cInsStationarySpeed))
    {
        CLLocation * lastLoc = [[CLLocation alloc] initWithLatitude:_lastStillRegion.center.latitude longitude:_lastStillRegion.center.longitude];
        if (forceSet || nil == _lastStillRegion || [lastLoc distanceFromLocation:loc] > 2*cReagionRadius)
        {
            DDLogWarn(@"&&&&&&&&&&&&&& add still region monitor for location(%@) = %@", REGION_ID_LAST_STILL, loc);
            result = [self registerNotificationForLocation:loc withRadius:@(cReagionRadius*1.8) assignIdentifier:REGION_ID_LAST_STILL group:REGION_GROUP_LAST_STILL];
        }
    }
    
    self.useSignificantLocationChange = (!result || (self.locationManager.monitoredRegions.count < 3));
}

- (void)setParkingLocation:(CLLocation*)loc;
{
    if (loc && CLLocationCoordinate2DIsValid(loc.coordinate))
    {
        DDLogWarn(@"&&&&&&&&&&&&&& add parking region monitor for location(%@) = %@", REGION_ID_LAST_PARKING, loc);
        [self registerNotificationForLocation:loc withRadius:@(cReagionRadius*1.5) assignIdentifier:REGION_ID_LAST_PARKING group:REGION_GROUP_LAST_PARKING];
        
        NSInteger idCnt = 1;
        TripSummary * lastTrip = [[AnaDbManager sharedInst] lastTrip];
        ParkingRegion * lastSt = lastTrip.region_group.start_region;
        
        if (lastSt) {
            CLLocation * lastStLoc = [[CLLocation alloc] initWithLatitude:[lastSt.center_lat doubleValue] longitude:[lastSt.center_lon doubleValue]];
            if ([lastStLoc distanceFromLocation:loc] > 500) {
                [self registerNotificationForLocation:lastStLoc withRadius:@(2*cReagionRadius) assignIdentifier:REGION_ID_MOST_PARKING(idCnt++) group:REGION_GROUP_MOST_STAY];
            }
        }
        
        NSArray * mostUsedLoc = [[AnaDbManager sharedInst] mostUsedParkingRegionLimit:5];
        for (ParkingRegionDetail * region in mostUsedLoc) {
            if (region.coreDataItem != lastSt) {
                CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:region.region.center.latitude longitude:region.region.center.longitude];
                if ([curLoc distanceFromLocation:loc] > 500) {
                    [self registerNotificationForLocation:curLoc withRadius:@(2*cReagionRadius) assignIdentifier:REGION_ID_MOST_PARKING(idCnt++) group:REGION_GROUP_MOST_STAY];
                }
            }
        }
    }
}

@end
