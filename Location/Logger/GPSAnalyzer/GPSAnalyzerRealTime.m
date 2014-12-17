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
    
}

@property (nonatomic, strong) NSTimer *                 lostGPSTimer;

@property (nonatomic, strong) NSMutableArray *          logArr;
@property (nonatomic, strong) GPSLogItem *              lastLogItem;
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
        self.logArr = [NSMutableArray arrayWithCapacity:128];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExitReagion:) name:kNotifyExitReagion object:nil];
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
        [self setLastGoodGPS:gps];
    }
    
    [self.lostGPSTimer invalidate];
    self.lostGPSTimer = nil;
    
    CGFloat speed = [gps.speed floatValue] < 0 ? 0 : [gps.speed floatValue];
    _startSpeedTrace += speed;
    _startSpeedTraceCnt++;
    _endSpeedTrace += speed;
    _endSpeedTraceCnt++;
    
    self.lastLogItem = gps;
    [self.logArr addObject:gps];
    
    if (speed > cInsTrafficJamSpeed) {
        _lastestNormalSpeed = gps.timestamp;
    }
    
    eMotionStat stat = [self checkStatus];
    [self removeOldData:([self eStat]!=stat)];
    [self setEStat:stat];
    
    if (eMotionStatDriving == stat) {
        self.lostGPSTimer = [NSTimer timerWithTimeInterval:cDriveEndThreshold target:self selector:@selector(didLostGPS) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.lostGPSTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void) removeOldData:(BOOL)force
{
    if (!force && _removeThreshold-- > 0) {
        return;
    }
    self.removeThreshold = 20;
    
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
            for (NSInteger i = _endSpeedTraceIdx; i < cnt; i++) {
                GPSLogItem * item = tmpArr[i];
                if ([thresDateEd compare:item.timestamp] == NSOrderedDescending) {
                    _endSpeedTrace -= ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
                    _endSpeedTraceCnt--;
                } else {
                    _endSpeedTraceIdx = i;
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
        if (inTrip) {
            if (_startMoveTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_startMoveTraceIdx]));
            }
        } else {
            if (_endSpeedTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //[[BussinessDataProvider sharedInstance] updateWeatherToday:[item location]];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyTripStatChange object:nil userInfo:(item ? @{@"date":item.timestamp, @"inTrip":_isInTrip, @"lat":item.latitude, @"lon":item.longitude} : @{@"inTrip":_isInTrip})];
        });

        DDLogWarn(@"!!!!!!!!!!!!!!!!!!!!!!!! notify is driving %d at %@", inTrip, item.timestamp);
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
    if (!isInTrip && eStat == eMotionStatDriving) {
        [self setIsInTrip:YES];
    } else if (isInTrip && (eStat < eMotionStatWalking)) {
        [self setIsInTrip:NO];
        
        // if the trip change from drive to stationary, reset all data to prevent cumulate error
        _startSpeedTrace = _endSpeedTrace = 0;
        _startSpeedTraceCnt = _endSpeedTraceCnt = 0;
        _startSpeedTraceIdx = _endSpeedTraceIdx = _startMoveTraceIdx = 0;
        [self.logArr removeAllObjects];
    }
}

- (eMotionStat) checkStatus
{
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
            NSTimeInterval driveDuring = [tracker duringForAutomationWithin:40];
            if (driveDuring > 5) {
                _endSpeedTrace = 0;
                _endSpeedTraceCnt = 0;
                _endSpeedTraceIdx = self.logArr.count-1;
                return eMotionStatDriving;
            } else if (driveDuring < 1 && [tracker duringForWalkRunWithin:40] > 8) {
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
