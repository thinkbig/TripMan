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
#import <Parse/Parse.h>
#import <CoreMotion/CoreMotion.h>

#define kWakeUpBySystem             @"kWakeUpBySystem"

@interface LocationTracker ()
{
    CLCircularRegion *            _lastParkingRegion;
    CLCircularRegion *            _lastStillRegion;
    BOOL                          _keepMonitoring;
    
    NSDate *                      _lastStationaryDate;
    
    NSInteger                     _recordCnt;
    
}

@property (nonatomic, strong) CMAccelerometerData *         lastAcceleraion;
@property (nonatomic, strong) NSTimer *                     timer;
@property (nonatomic, strong) NSTimer *                     stopTimer;

@end

@implementation LocationTracker

+ (CLLocationManager *)sharedLocationManager {
	static CLLocationManager *_locationManager;
	@synchronized(self) {
		if (_locationManager == nil) {
			_locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
		}
	}
	return _locationManager;
}

+ (CMMotionManager *)sharedMotionManager {
	static CMMotionManager *_motionManager;
	@synchronized(self) {
		if (_motionManager == nil) {
			_motionManager = [[CMMotionManager alloc] init];
            _motionManager.accelerometerUpdateInterval = 0.3;
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
        [self setKeepMonitor];
        [self preload];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tripStatChange:) name:kNotifyTripStatChange object:nil];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSignificantMonitor) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startLocationTracking) name:UIApplicationWillEnterForegroundNotification object:nil];
        
//        if ([CMMotionActivityManager isActivityAvailable]) {
//            CMMotionActivityManager * activityManager = [LocationTracker sharedMotionActivityManager];
//            [activityManager startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMotionActivity *activity) {
//                if (activity.automotive && !_keepMonitoring) {
//                    BOOL isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
//                    if (!isDriving) {
//                        DDLogWarn(@"^^^^^^^^^^^^^^^^^^^^^^^ isDriving = %d", activity.automotive);
//                        [self.stopTimer invalidate];
//                        self.stopTimer = nil;
//                        _lastStationaryDate = nil;
//                        _keepMonitoring = YES;
//                        [self startLocationTracking];
//                    }
//                }
//            }];
//        }
	}
	return self;
}

- (void)setKeepMonitor
{
    _keepMonitoring = YES;
    _lastStationaryDate = nil;
    _recordCnt = 20;
}

- (void)preload
{
    CLLocationManager * manager = [LocationTracker sharedLocationManager];
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
            GPSEvent5(statDate, eGPSEventDriveStart, theRegion, @"tripStEd", nil);
            // remove all monitor spot
            CLLocationManager * manager = [LocationTracker sharedLocationManager];
            NSSet * regions = manager.monitoredRegions;
            for (CLCircularRegion * region in regions) {
                [manager stopMonitoringForRegion:region];
            }
        } else {
            GPSEvent5(statDate, eGPSEventDriveEnd, theRegion, @"tripStEd", nil);
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
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [[BackgroundTaskManager sharedBackgroundTaskManager] beginNewBackgroundTask];

    CMMotionManager *motionManager = [LocationTracker sharedMotionManager];
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                            if(error){
                                                DDLogWarn(@"CMMotionManager error: %@", error);
                                            } else {
                                                self.lastAcceleraion = accelerometerData;
                                            }
                                        }];

    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
	CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
        DDLogWarn(@"authorizationStatus failed");
        GPSEvent([NSDate date], eGPSEventGPSDeny);
    } else if (kCLAuthorizationStatusAuthorizedAlways == authorizationStatus) {
        DDLogInfo(@"authorizationStatus authorized");
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        [locationManager startMonitoringSignificantLocationChanges];
        [locationManager startUpdatingLocation];
        GPSEvent([NSDate date], eGPSEventStartGPS);
    } else if (kCLAuthorizationStatusNotDetermined == authorizationStatus) {
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // ios 8
            [locationManager requestAlwaysAuthorization];
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            locationManager.pausesLocationUpdatesAutomatically = NO;
            [locationManager startMonitoringSignificantLocationChanges];
            [locationManager startUpdatingLocation];
            GPSEvent([NSDate date], eGPSEventStartGPS);
        }
    }
}

- (void)realStop
{
    CMMotionManager *motionManager = [LocationTracker sharedMotionManager];
    [motionManager stopAccelerometerUpdates];
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
	[locationManager stopUpdatingLocation];
    [locationManager startMonitoringSignificantLocationChanges];

    GPSEvent([NSDate date], eGPSEventStopGPS);
}

- (void)stopLocationTracking {
    DDLogWarn(@"stopLocationTracking");
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self realStop];
}

- (BOOL)registerNotificationForLocation:(CLLocation *)myLocation withRadius:(NSNumber *)myRadius assignIdentifier:(NSString *)identifier group:(NSString*)groupName
{
    // Do not create regions if support is unavailable or disabled.
    if ( ![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        return NO;
    }
    
    // If the radius is too large, registration fails automatically,
    // so clamp the radius to the max value.
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    CLLocationDistance theRadius = [myRadius doubleValue];
    if (theRadius > locationManager.maximumRegionMonitoringDistance) {
        theRadius = locationManager.maximumRegionMonitoringDistance;
    }
    
    CLLocationCoordinate2D theCoordinate = myLocation.coordinate;
    
    // Create the region and start monitoring it.
    
    identifier = identifier.length > 0 ? identifier : @"DefaultReagionId";
    groupName = groupName.length > 0 ? groupName : @"DefaultReagionGroup";
    
    CLCircularRegion* theRegion = [[CLCircularRegion alloc] initWithCenter:theCoordinate radius:theRadius identifier:[self regionId:identifier withGroup:groupName]];
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
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


#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self startLocationTracking];
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
    [self.stopTimer invalidate];
    self.stopTimer = nil;
    [self startLocationTracking];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([PFInstallation currentInstallation].deviceToken) {
            DDLogWarn(@"send silent push !!!!!!");
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"deviceToken" equalTo:[PFInstallation currentInstallation].deviceToken]; // Set channel
    
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery];
            //[push setMessage:@"Push by device token"];
            [push setData:@{@"aps":@{@"content-available":@1, @"sound":@""}}];
            [push sendPushInBackground];
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLCircularRegion *)region withError:(NSError *)error
{
    DDLogWarn(@"locationManager monitoringDidFailForRegion");
    [self recordEvent:eGPSEventMonitorFail forReagion:region];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    DDLogInfo(@"locationManager didUpdateLocations");
    
    NSNumber * wakeupBySys = [[NSUserDefaults standardUserDefaults] objectForKey:kWakeUpBySystem];
    if (nil == wakeupBySys || [wakeupBySys boolValue]) {
        [self setKeepMonitor];
        [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:kWakeUpBySystem];
    }
        
    CLLocationAccuracy mostAccuracy = MAXFLOAT;
    CLLocation * mostAccuracyLocation = nil;
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 60.0) {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil && theAccuracy>0 && theAccuracy<500 && (!(theLocation.latitude==0.0 && theLocation.longitude==0.0))){
            GPSLog(newLocation, self.lastAcceleraion);
            if (mostAccuracy > theAccuracy) {
                mostAccuracy = theAccuracy;
                mostAccuracyLocation = newLocation;
            }
        }
    }
    
    if (nil == mostAccuracyLocation) {
        return;
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [[BackgroundTaskManager sharedBackgroundTaskManager] beginNewBackgroundTask];
        
    BOOL isDriving = [[[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip] boolValue];
    eMotionStat stat = (eMotionStat)[[[NSUserDefaults standardUserDefaults] objectForKey:kMotionCurrentStat] integerValue];
    
    static BOOL lastStat = NO;
    if (lastStat != isDriving) {
        DDLogWarn(@"drive stat change to: %d", isDriving);
        lastStat = isDriving;
        _recordCnt = 20;
    }
    static NSInteger recordInterval = 0;
    if (_recordCnt-- > 0 || recordInterval++%20 == 0) {
        DDLogWarn(@"location is: <%f, %f>, speed=%f, accuracy=%f, altitude=%f", mostAccuracyLocation.coordinate.latitude, mostAccuracyLocation.coordinate.longitude, mostAccuracyLocation.speed, mostAccuracyLocation.horizontalAccuracy, mostAccuracyLocation.altitude);
    }
    
    if (isDriving)
    {
        _keepMonitoring = NO;
        _lastStationaryDate = nil;
        CGFloat cof = 1.0f;
        if (mostAccuracyLocation.speed  < cInsStationarySpeed) cof = 2.0f;
        else if (mostAccuracyLocation.speed  < cInsWalkingSpeed) cof = 1.5f;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:10*cof target:self
                                                    selector:@selector(startLocationTracking)
                                                    userInfo:nil
                                                     repeats:NO];
        [self.stopTimer invalidate];
        self.stopTimer = nil;
    }
    else
    {
        CGFloat cof = 1.0f;
        if (mostAccuracyLocation.speed >= 0) {
            if (mostAccuracyLocation.speed  < cInsStationarySpeed) cof = 3.0f;
            else if (mostAccuracyLocation.speed  < cInsWalkingSpeed) cof = 2.0f;
            else if (mostAccuracyLocation.speed  < cInsRunningSpeed) cof = 1.5f;
            else if (mostAccuracyLocation.speed < 0 && mostAccuracyLocation.horizontalAccuracy > 100) cof = 0.5f;   // warming up gps
        }
        
        if (_keepMonitoring) {
            if (mostAccuracyLocation.speed > cInsDrivingSpeed || (mostAccuracyLocation.speed < 0 && mostAccuracyLocation.horizontalAccuracy > 100)) {
                // already driving OR the gps is warming
                _lastStationaryDate = nil;
            }
            if (_lastStationaryDate && [mostAccuracyLocation.timestamp timeIntervalSinceDate:_lastStationaryDate] > cCanStopMonitoringThreshold) {
                _keepMonitoring = NO;
            }
            if (nil == _lastStationaryDate && mostAccuracyLocation.speed < cInsWalkingSpeed) {
                _lastStationaryDate = mostAccuracyLocation.timestamp;
            }
        }

        if (_keepMonitoring) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:10*cof target:self
                                                        selector:@selector(startLocationTracking)
                                                        userInfo:nil
                                                         repeats:NO];
        }
        
        //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
        //The location manager will only operate for 10 seconds to save battery
        //if the instant speed is -1, means the gps module has just be waken
        if (!_keepMonitoring && nil == self.stopTimer && mostAccuracyLocation.speed < cInsWalkingSpeed && stat < eMotionStatWalking) {
            [self setStillLocation:mostAccuracyLocation force:NO];
            self.stopTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                            selector:@selector(stopLocationDelayBy10Seconds)
                                                            userInfo:nil
                                                             repeats:NO];
        }
    }
}

//Stop the locationManager
-(void)stopLocationDelayBy10Seconds
{
    [self.stopTimer invalidate];
    self.stopTimer = nil;
    
    [self realStop];
    
    CLLocation * lastGoodGPS = [BussinessDataProvider lastGoodLocation];
    if (lastGoodGPS) {
        [self setStillLocation:lastGoodGPS force:YES];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kWakeUpBySystem];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
    
    DDLogWarn(@"######## locationManager stop Updating after 10 seconds");
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
    DDLogInfo(@"locationManager error:%@",error);
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
