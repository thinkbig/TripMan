//
//  LocationTracker.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location All rights reserved.
//

#import "LocationTracker.h"
#import "AppDelegate.h"
#import "BackgroundTaskManager.h"
#import "GPSAnalyzerRealTime.h"
#import "GPSOffTimeFilter.h"
#import <Parse/Parse.h>
#import <CoreMotion/CoreMotion.h>
#import "TSPair.h"

#define kLocationUpdateInterval         7
#define kLocationUpdateLongInterval     15

#define kWakeUpBySystem             @"kWakeUpBySystem"
#define kLocationAccu               kCLLocationAccuracyBest
#define kLocationAccuNotDriving     kCLLocationAccuracyBest

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
    
    NSDate *                      _lastStationaryDate;
    
    NSInteger                     _recordCnt;
    
    BOOL                          _locationStarted;
    BOOL                          _setShoudlStop;
    
    CLLocation *                  _lastLastLoc;
    CLLocation *                  _lastLoc;
}

@property (nonatomic, strong) CMAccelerometerData *         lastAcceleraion;

@property (nonatomic) LTMotionType                          eCurrentMotion;
@property (nonatomic, strong) NSMutableArray *              motionArray;
@property (nonatomic) BOOL                                  isDetectMotion;

@property (nonatomic, strong) NSTimer *                     restartTimer;
@property (nonatomic) BOOL                                  isDriving;

@end

@implementation LocationTracker

- (CLLocationManager *)locationManager
{
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kLocationAccu;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
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
        _locationStarted = NO;
        [self setKeepMonitor];
        [self preload];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tripStatChange:) name:kNotifyTripStatChange object:nil];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSignificantMonitor) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startLocationTracking) name:UIApplicationWillEnterForegroundNotification object:nil];
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
    NSArray * copyArr = [self.motionArray copy];
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
    NSArray * copyArr = [self.motionArray copy];
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
            // remove all monitor spot
            CLLocationManager * manager = self.locationManager;
            NSSet * regions = manager.monitoredRegions;
            for (CLCircularRegion * region in regions) {
                [manager stopMonitoringForRegion:region];
            }
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

- (void)realStop
{
    [self.restartTimer invalidate];
    self.restartTimer = nil;
    
    if (_setShoudlStop) {
        return;
    }
    _setShoudlStop = YES;
    _lastLoc = _lastLastLoc = nil;
    
    DDLogWarn(@"realStopLocationTracking");
    
    CMMotionManager *motionManager = [LocationTracker sharedMotionManager];
    [motionManager stopAccelerometerUpdates];
    
    CLLocationManager *locationManager = self.locationManager;
	[locationManager stopUpdatingLocation];
    [locationManager stopMonitoringSignificantLocationChanges];

    [self stopMotionChecker];
    
    CLLocation * lastGoodGPS = [BussinessDataProvider lastGoodLocation];
    if (lastGoodGPS) {
        [self setStillLocation:lastGoodGPS force:YES];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kWakeUpBySystem];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
    
    GPSEvent([NSDate date], eGPSEventStopGPS);
}

- (BOOL)registerNotificationForLocation:(CLLocation *)myLocation withRadius:(NSNumber *)myRadius assignIdentifier:(NSString *)identifier group:(NSString*)groupName
{
    // Do not create regions if support is unavailable or disabled.
    if ( ![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
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
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLCircularRegion *)region
{
    DDLogWarn(@"locationManager didEnterRegion: %@", region.identifier);
    
    [self recordEvent:eGPSEventEnterRegion forReagion:region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLCircularRegion *)region
{
    DDLogWarn(@"locationManager didExitRegion: %@", region.identifier);
    
    [self recordEvent:eGPSEventExitRegion forReagion:region];
    
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

- (BOOL) isGPSWarning:(CLLocation*)loc
{
    return (loc.speed < 0 && loc.horizontalAccuracy > 100);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"locationManager didUpdateLocations");
    
    BOOL isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
    
    NSNumber * wakeupBySys = [[NSUserDefaults standardUserDefaults] objectForKey:kWakeUpBySystem];
    if (nil == wakeupBySys || [wakeupBySys boolValue]) {
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
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil && theAccuracy>0 && theAccuracy<400 && (!(theLocation.latitude==0.0 && theLocation.longitude==0.0)))
        {
            BOOL isMost = NO;
            if (mostAccuracy > theAccuracy) {
                mostAccuracy = theAccuracy;
                mostAccuracyLocation = newLocation;
                calSpeed = mostAccuracyLocation.speed;
                isMost = YES;
            }
            
            CGFloat speed = newLocation.speed;
            if (newLocation.speed < 0 && _lastLoc) {
                NSTimeInterval interval = [newLocation.timestamp timeIntervalSinceDate:_lastLoc.timestamp];
                CGFloat dist1 = [newLocation distanceFromLocation:_lastLoc];
                if (interval > 2 && dist1 > 5 && newLocation.horizontalAccuracy < 200 && _lastLoc.horizontalAccuracy < 200) {
                    // if the gps signal is too low, we can not cal the speed
                    CGFloat tmpSpeed = dist1/interval;
                    if (tmpSpeed < cAvgNoiceSpeed) {
                        if (!isDriving) {
                            if (_lastLastLoc) {
                                CGFloat angle = [GPSOffTimeFilter checkPotinAngle:[GPSOffTimeFilter coor2Point:_lastLastLoc.coordinate] antPt:[GPSOffTimeFilter coor2Point:_lastLoc.coordinate] antPt:[GPSOffTimeFilter coor2Point:newLocation.coordinate]];
                                if (angle < 90) {
                                    // filter the wrong gps
                                    speed = tmpSpeed;
                                }
                            }
                        } else {
                            speed = tmpSpeed;
                        }
                        if (isMost) {
                            calSpeed = speed;
                        }
                    }
                }
            }
            _lastLastLoc = _lastLoc;
            _lastLoc = newLocation;
            
            GPSLog2(newLocation, self.lastAcceleraion, speed);
        }
    }
    
    if (nil == mostAccuracyLocation) {
        DDLogWarn(@"good location is not valid, keep start");
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
        return;
    }

    BOOL isWarming = [self isGPSWarning:mostAccuracyLocation];
    if (self.isDriving != isDriving) {
        DDLogWarn(@"drive stat change to: %d", isDriving);
        self.isDriving = isDriving;
        _recordCnt = 20;
    }
    static NSInteger recordInterval = 0;
    if (_recordCnt-- > 0 || recordInterval++%5 == 0) {
        DDLogWarn(@"location is: <%f, %f>, speed=%f, accuracy=%f, altitude=%f", mostAccuracyLocation.coordinate.latitude, mostAccuracyLocation.coordinate.longitude, calSpeed, mostAccuracyLocation.horizontalAccuracy, mostAccuracyLocation.altitude);
    }
    
    if (!isDriving)
    {
        if (_keepMonitoring) {
            if (calSpeed > cInsDrivingSpeed || isWarming) {
                // already driving OR the gps is warming
                _lastStationaryDate = nil;
            }
            if (_lastStationaryDate && [mostAccuracyLocation.timestamp timeIntervalSinceDate:_lastStationaryDate] > cCanStopMonitoringThreshold) {
                _keepMonitoring = NO;
            }
            if (nil == _lastStationaryDate && calSpeed < cInsWalkingSpeed) {
                _lastStationaryDate = mostAccuracyLocation.timestamp;
            }
            [self startMotionChecker];
            if ([self duringForAutomationWithin:20] > 8) {
                DDLogWarn(@"&&&&&&&&&&&&& motion regard as drive start &&&&&&&&&&&&& ");
                _keepMonitoring = YES;
            } else if ([self duringForWalkRunWithin:40] > 8) {
                DDLogWarn(@"&&&&&&&&&&&&& motion regard as walking, stop monitor &&&&&&&&&&&&& ");
                _keepMonitoring = NO;
            }
        }
        
        //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
        //The location manager will only operate for 10 seconds to save battery
        //if the instant speed is -1, means the gps module has just be waken
        if (!_keepMonitoring) {
            [self setStillLocation:mostAccuracyLocation force:NO];
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
        if (calSpeed > cInsDrivingSpeed || isDriving) {
            interval = kLocationUpdateInterval;
        }
        if (isDriving) {
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
    if (forceSet || (loc && CLLocationCoordinate2DIsValid(loc.coordinate) && loc.speed <= cInsStationarySpeed))
    {
        CLLocation * lastLoc = [[CLLocation alloc] initWithLatitude:_lastStillRegion.center.latitude longitude:_lastStillRegion.center.longitude];
        if (forceSet || nil == _lastStillRegion || [lastLoc distanceFromLocation:loc] > 2*cReagionRadius)
        {
            DDLogWarn(@"&&&&&&&&&&&&&& add still reagion monitor for location = %@", loc);
            [self registerNotificationForLocation:loc withRadius:@(cReagionRadius) assignIdentifier:REGION_ID_LAST_STILL group:REGION_GROUP_LAST_STILL];
        }
    }
}

- (void)setParkingLocation:(CLLocation*)loc;
{
    if (loc && CLLocationCoordinate2DIsValid(loc.coordinate))
    {
        DDLogWarn(@"&&&&&&&&&&&&&& add parking reagion monitor for location = %@", loc);
        [self registerNotificationForLocation:loc withRadius:@(cReagionRadius) assignIdentifier:REGION_ID_LAST_PARKING group:REGION_GROUP_LAST_PARKING];
    }
}

@end
