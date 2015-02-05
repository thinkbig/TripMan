//
//  DriveProcessAnalyzer.m
//  Location
//
//  Created by taq on 9/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSAnalyzerRealTime.h"
#import <CoreMotion/CoreMotion.h>
#import "LocationTracker.h"
#import "GPSOffTimeFilter.h"

@interface GPSAnalyzerRealTime () {
    
    CGFloat     _startSpeedTrace;
    NSInteger   _startSpeedTraceCnt;
    NSInteger   _startSpeedTraceIdx;
    
    //CGFloat     _startMoveTrace;
    //NSInteger   _startMoveTraceCnt;
    NSInteger   _startMoveTraceIdx;
    
    CGFloat     _endSpeedTrace;
    NSInteger   _endSpeedTraceCnt;
    NSInteger   _endSpeedTraceIdx;
    
    NSDate *    _lastestNormalSpeed;
    
    NSNumber *          _isInTrip;
    NSNumber *          _eStat;
    NSDictionary *      _lastGoodGPS;
    NSDate *            _lastExitReagionDate;
    
    GPSLogItem *        _driveStart;
    GPSLogItem *        _maxDistItem;
    CGFloat             _maxDist;
    
}

@property (nonatomic, strong) NSTimer *                 lostGPSTimer;

@property (nonatomic, strong) NSMutableArray *          logArr;
@property (nonatomic, strong) GPSLogItem *              lastLogItem;
@property (nonatomic, strong) GPSLogItem *              locChangeLogItem;
@property (nonatomic, strong) NSMutableArray *          angleArr;
@property (nonatomic) NSInteger                         removeThreshold;

@end


@implementation GPSAnalyzerRealTime

- (instancetype)init
{
    self = [super init];
    if (self) {
        _startMoveTraceIdx = 0;
        _startSpeedTraceIdx = 0;
        _endSpeedTraceIdx = 0;
        self.removeThreshold = 20;
        self.locChangeLogItem = nil;
        self.angleArr = [NSMutableArray arrayWithCapacity:128];
        self.logArr = [NSMutableArray arrayWithCapacity:128];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExitReagion:) name:kNotifyExitReagion object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLostGPS) name:kNotifyGpsLost object:nil];
    }
    return self;
}

- (void)didExitReagion:(NSNotification*)notify
{
    _lastExitReagionDate = notify.userInfo[@"date"];
}

- (void)didLostGPS
{
    DDLogWarn(@"gps lost!!!!!!!!!!!!!!!!!");
    [self.lostGPSTimer invalidate];
    self.lostGPSTimer = nil;
    if ([self isInTrip]) {
        [self removeOldData:([self eStat]!=eMotionStatGPSLost)];
        [self setEStat:eMotionStatGPSLost];
    }
}

- (NSDictionary*)lastGoodGPS
{
    if (nil == _lastGoodGPS) {
        _lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
    }
    return _lastGoodGPS;
}

- (void)setLastGoodGPS:(GPSLogItem*)gps
{
    if (gps) {
        _lastGoodGPS = @{@"timestamp":gps.timestamp, @"lat":gps.latitude, @"lon":gps.longitude};
        [[NSUserDefaults standardUserDefaults] setObject:_lastGoodGPS forKey:kLastestGoodGPSData];
    }
}

- (void) appendGPSInfo:(GPSLogItem*)gps
{
    if (gps.timestamp)
    {
        NSDictionary * lastDate = [self lastGoodGPS];
        if (lastDate && [gps.timestamp timeIntervalSinceDate:lastDate[@"timestamp"]] > cOntOfDateThreshold) {
            //[self removeOldData:YES];
            _startSpeedTrace = _endSpeedTrace = 0;
            _startSpeedTraceCnt = _endSpeedTraceCnt = 0;
            _startSpeedTraceIdx = _endSpeedTraceIdx = _startMoveTraceIdx = 0;
            [self.logArr removeAllObjects];
            [self setEStat:eMotionStatGPSLost];
        }
        if ([gps.horizontalAccuracy doubleValue] < kPoorHorizontalAccuracy) {
            [self setLastGoodGPS:gps];
        }
    }
    
    [self.lostGPSTimer invalidate];
    self.lostGPSTimer = nil;
    CGFloat accu = [gps.horizontalAccuracy doubleValue];
    
    CGFloat speed = [gps.speed floatValue] < 0 ? 0 : [gps.speed floatValue];
    if (speed > cInsDrivingSpeed && accu > kLowHorizontalAccuracy && ![_isInTrip boolValue] && _startMoveTraceIdx < self.logArr.count) {
        GPSLogItem * firstItem = self.logArr[_startMoveTraceIdx];
        // lower the speed if it is a low accuracy and near the start move point
        if ([gps distanceFrom:firstItem] < 500) {
            speed /= 2.0;
            gps.speed = @(speed);
        }
    }
    
    BOOL validSpeed = YES;
    if (self.lastLogItem && speed == 0 && accu > kGoodHorizontalAccuracy && [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp] < 1) {
        validSpeed = NO;
    }
    
    GPSLogItem * lastGps = self.lastLogItem;
    if (validSpeed) {
        _startSpeedTrace += speed;
        _startSpeedTraceCnt++;
        _endSpeedTrace += speed;
        _endSpeedTraceCnt++;
        
        self.lastLogItem = gps;
        [self.logArr addObject:gps];
        
        if (speed > cInsTrafficJamSpeed) {
            _lastestNormalSpeed = gps.timestamp;
        }
    }
    
    eMotionStat stat = [self checkStatus];
    
    if (_driveStart) {
        CGFloat distFromStart = [gps distanceFrom:_driveStart];
        _maxDist = MAX(distFromStart, _maxDist);
    }
    if ([_isInTrip boolValue] && [gps.horizontalAccuracy doubleValue] > kLowHorizontalAccuracy) {
        if ([gps.timestamp timeIntervalSinceDate:_driveStart.timestamp] > 10*60) {
            // the car should drive at least 420 meter after start drive 10 min
            if (_maxDist > 0 && _maxDist < 400) {
                stat = eMotionStatStationary;
            }
        }
    }
    
    if (nil == self.locChangeLogItem) {
        self.locChangeLogItem = gps;
    } else if (validSpeed) {
        CGFloat dist = [self.locChangeLogItem distanceFrom:gps];
        if (dist > 400) {
            self.locChangeLogItem = gps;
            [self.angleArr removeAllObjects];
        } else {
            if (self.lastLogItem && stat > eMotionStatStationary) {
                CGFloat angle = [GPSOffTimeFilter angleFromPoint:[GPSOffTimeFilter coor2Point:lastGps.locationCoordinate] toPoint:[GPSOffTimeFilter coor2Point:gps.locationCoordinate]];
                [self.angleArr addObject:@(angle)];
                NSTimeInterval during = [gps.timestamp timeIntervalSinceDate:self.locChangeLogItem.timestamp];
                // the car should drive at least 420 meter after start drive 10 min
                if (during > 10*60 && self.angleArr.count > 0) {
                    // check if the angle is in a line
                    CGFloat tolAngle = 0;
                    for (NSNumber * angle in self.angleArr) {
                        tolAngle += [angle floatValue];
                    }
                    CGFloat avgAngle = tolAngle/self.angleArr.count;
                    CGFloat diff = 0;
                    for (NSNumber * angle in self.angleArr) {
                        diff += fabsf([angle floatValue]-avgAngle);
                    }
                    diff /= self.angleArr.count;
                    if (diff > 60) {
                        // move less than 400 in 10 min, and the direction is jumping
                        stat = eMotionStatStationary;
                    }
                    self.locChangeLogItem = gps;
                    [self.angleArr removeAllObjects];
                }
            }
            
        }
    }

    [self removeOldData:([self eStat]!=stat)];
    [self setEStat:stat];
    
    if (eMotionStatDriving == stat) {
        self.lostGPSTimer = [NSTimer timerWithTimeInterval:20*60 target:self selector:@selector(didLostGPS) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.lostGPSTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void) removeOldData:(BOOL)force
{
    if (!force && _removeThreshold-- > 0) {
        return;
    }
    self.removeThreshold = 7;
    
    GPSLogItem * lastItem = self.lastLogItem;
    if (lastItem) {
        
        NSArray * tmpArr = self.logArr;
        NSInteger cnt = tmpArr.count;
        
        // start drive
        NSDate * thresDateSt = [lastItem.timestamp dateByAddingTimeInterval:-cDriveStartThreshold];
        for (NSInteger i = _startSpeedTraceIdx; i < cnt; i++) {
            GPSLogItem * item = tmpArr[i];
            if ([thresDateSt compare:item.timestamp] == NSOrderedDescending) {
                _startSpeedTrace -= ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
                _startSpeedTraceCnt--;
            } else {
                _startSpeedTraceIdx = i;
                break;
            }
        }
        
        // start move
        NSDate * thresDateStMove = [lastItem.timestamp dateByAddingTimeInterval:-cMoveStartRecordThreshold];
        if (_lastExitReagionDate) {
            thresDateStMove = [thresDateStMove laterDate:_lastExitReagionDate];
        }
        BOOL findMoveStart = NO;
        for (NSInteger i = _startMoveTraceIdx; i < _startSpeedTraceIdx; i++) {
            GPSLogItem * item = tmpArr[i];
            CGFloat speed = [item.speed floatValue];
            // if the gps has just started, the speed will shown as -1, but the location data is valiad
            if ([thresDateStMove compare:item.timestamp] == NSOrderedDescending || (!findMoveStart && speed < cAvgStationarySpeed && speed >= 0)) {
                if (!findMoveStart && (speed < 0 || speed >= cAvgStationarySpeed)) {
                    findMoveStart = YES;
                }
            } else {
                _startMoveTraceIdx = i;
                break;
            }
        }
        
        // end drive
        CGFloat speed = [lastItem.speed floatValue] < 0 ? 0 : [lastItem.speed floatValue];
        if (speed > cInsDrivingSpeed) {
            // still in drive, reset the end point
            _endSpeedTrace = speed;
            _endSpeedTraceCnt = 1;
            _endSpeedTraceIdx = cnt-1;
        } else {
            NSDate * thresDateEd = [lastItem.timestamp dateByAddingTimeInterval:-cDriveEndThreshold];
            for (NSInteger i = _endSpeedTraceIdx; i < cnt-cDirveEndSamplePoint; i++) {
                GPSLogItem * item = tmpArr[i];
                if ([thresDateEd compare:item.timestamp] == NSOrderedDescending) {
                    _endSpeedTrace -= ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
                    _endSpeedTraceCnt--;
                    _endSpeedTraceIdx = i+1;
                } else {
                    _endSpeedTraceIdx = i+1;
                    break;
                }
            }
        }
    }
    
    NSInteger oldestIdx = MIN(_endSpeedTraceIdx, _startMoveTraceIdx);
    if (oldestIdx > 64) {
        [self.logArr removeObjectsInRange:NSMakeRange(0, oldestIdx)];
        _startSpeedTraceIdx -= oldestIdx;
        _startMoveTraceIdx -= oldestIdx;
        _endSpeedTraceIdx -= oldestIdx;
    }
}

- (BOOL)isInTrip
{
    if (nil == _isInTrip) {
        _isInTrip = [[NSUserDefaults standardUserDefaults] objectForKey:kMotionIsInTrip];
    }
    if (_isInTrip) {
        return [_isInTrip boolValue];
    }
    return NO;
}

- (void)setIsInTrip:(BOOL)inTrip
{
    if (nil == _isInTrip || inTrip != [_isInTrip boolValue]) {
        _isInTrip = @(inTrip);
        [[NSUserDefaults standardUserDefaults] setObject:_isInTrip forKey:kMotionIsInTrip];
        
        __block GPSLogItem * item = nil;
        BOOL dropTrip = NO;
        if (inTrip) {
            if (_startMoveTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_startMoveTraceIdx]));
                _driveStart = item;
                _maxDist = 0;
                _maxDistItem = nil;
            }
        } else {
            if (_endSpeedTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
                if (_maxDist < 400) {
                    dropTrip = YES;
                }
                _maxDist = 0;
                _driveStart = _maxDistItem = nil;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //[[BussinessDataProvider sharedInstance] updateWeatherToday:[item location]];
            NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_isInTrip, @"inTrip", @(dropTrip), @"dropTrip", nil];
            if (item) {
                dict[@"date"] = item.timestamp;
                dict[@"lat"] = item.latitude;
                dict[@"lon"] = item.longitude;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyTripStatChange object:nil userInfo:dict];
        });

        DDLogWarn(@"!!!!!!!!!!!!!!!!!!!!!!!! notify is driving %d at %@, if drop %d, maxDist %f", inTrip, item.timestamp, dropTrip, _maxDist);
    }
}

- (eMotionStat)eStat
{
    if (nil == _eStat) {
        _eStat = [[NSUserDefaults standardUserDefaults] objectForKey:kMotionCurrentStat];
    }
    if (_eStat) {
        return (eMotionStat)[_eStat integerValue];
    }
    return eMotionStatGPSLost;
}

- (void)setEStat:(eMotionStat)eStat
{
    if (nil == _eStat || [_eStat integerValue] != eStat) {
        _eStat = @(eStat);
        [[NSUserDefaults standardUserDefaults] setObject:_eStat forKey:kMotionCurrentStat];
    }
    
    BOOL isInTrip = [self isInTrip];
    if (!isInTrip && eStat == eMotionStatDriving)
    {
        [self setIsInTrip:YES];
        [self.angleArr removeAllObjects];
        self.locChangeLogItem = nil;
    }
    else if (isInTrip && (eStat < eMotionStatWalking))
    {
        [self setIsInTrip:NO];
        
        // if the trip change from drive to stationary, reset all data to prevent cumulate error
        _startSpeedTrace = _endSpeedTrace = 0;
        _startSpeedTraceCnt = _endSpeedTraceCnt = 0;
        _startSpeedTraceIdx = _endSpeedTraceIdx = _startMoveTraceIdx = 0;
        [self.angleArr removeAllObjects];
        self.locChangeLogItem = nil;
        [self.logArr removeAllObjects];
    }
}

- (eMotionStat) checkStatus
{
    if (DEBUG_MODE && IS_FORCE_DRIVING) {
        NSLog(@"Debug mode: forse driving");
        return eMotionStatDriving;
    }
    eMotionStat newStat = [self eStat];
    if (![self isInTrip]) {
        // check if start driving
        if (_startSpeedTraceCnt > cDirveStartSamplePoint) {
            CGFloat avgSpeed = _startSpeedTrace/_startSpeedTraceCnt;
            if (avgSpeed  > cAvgDrivingSpeed) {
                newStat = eMotionStatDriving;
            } else if (avgSpeed  > cAvgRunningSpeed) {
                newStat = eMotionStatRunning;
            } else if (avgSpeed  > cAvgWalkingSpeed) {
                newStat = eMotionStatWalking;
            } else {
                newStat = eMotionStatStationary;
            }
            NSLog(@"$$$$$$$$$$$$$$$$$$$$$ start speed = %f", avgSpeed);
        }
    } else {
        // fast deside using M7 chrip
        if (_lastestNormalSpeed && [[NSDate date] timeIntervalSinceDate:_lastestNormalSpeed] >= 20) {
            LocationTracker * tracker = ((AppDelegate*)([UIApplication sharedApplication].delegate)).locationTracker;
            NSTimeInterval driveDuring = [tracker duringForAutomationWithin:60];
            if (driveDuring > 5) {
                _endSpeedTrace = 0;
                _endSpeedTraceCnt = 0;
                _endSpeedTraceIdx = self.logArr.count-1;
                return eMotionStatDriving;
            } else if (driveDuring < 1 && [tracker duringForWalkRunWithin:60] > 20) {
                DDLogWarn(@"&&&&&&&&&&&&& motion regard as drive stop &&&&&&&&&&&&& ");
                _endSpeedTrace = 0;
                _endSpeedTraceCnt = 0;
                _endSpeedTraceIdx = self.logArr.count-1;
                return eMotionStatStationary;
            }
        }
        if (_endSpeedTraceCnt > cDirveEndSamplePoint && _endSpeedTraceIdx < self.logArr.count) {
            GPSLogItem * item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
            if ([[NSDate date] timeIntervalSinceDate:item.timestamp] >= cDriveEndThreshold*0.6) {
                CGFloat avgSpeed = _endSpeedTrace/_endSpeedTraceCnt;
                if (avgSpeed  < cAvgStationarySpeed) {
                    newStat = eMotionStatStationary;
                } else if (avgSpeed  < cAvgWalkingSpeed) {
                    newStat = eMotionStatWalking;
                } else if (avgSpeed  < cAvgRunningSpeed) {
                    newStat = eMotionStatRunning;
                } else {
                    newStat = eMotionStatDriving;
                }
                NSLog(@"$$$$$$$$$$$$$$$$$$$$$ end speed = %f", avgSpeed);
            }
        }
    }
    return newStat;
}


#pragma mark - DDLogger

- (void)logMessage:(DDLogMessage *)logMessage
{
    if (formatter && nil == [formatter formatLogMessage:logMessage]){
        return;
    }
    switch (logMessage->logFlag) {
        case LOG_FLAG_GPS_DATA:
        {
            GPSLogItem *logItem = [[GPSLogItem alloc] initWithLogMessage:logMessage];
            if (logItem.isValid) {
                [self appendGPSInfo:logItem];
            }
            break;
        }
        case LOG_FLAG_GPS_EVENT:
            break;
            
        default:
            break;
    }
}

- (NSString *)loggerName
{
	return @"com.gps.logger.analyzer";
}

@end
