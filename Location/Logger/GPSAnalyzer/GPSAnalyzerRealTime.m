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
    NSDate *            _lastExitReagionDate;
    
    CLLocation *        _lastMonitorLoc;
    GPSLogItem *        _driveStart;
    CGFloat             _maxDist;
    CGFloat             _maxDist2Monitor;
    
    CGFloat             _endThreshold;
    
}

@property (nonatomic, strong) NSTimer *                 lostGPSTimer;

@property (nonatomic, strong) NSMutableArray *          logArr;
@property (nonatomic, strong) GPSLogItem *              lastLogItem;
@property (nonatomic, strong) GPSLogItem *              locChangeLogItem;
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
        _endThreshold = cDriveEndThreshold;
        self.removeThreshold = cDirveStartSamplePoint*2;
        self.locChangeLogItem = nil;
        self.logArr = [NSMutableArray arrayWithCapacity:128];
        self.jamAnalyzer = [GPSInstJamAnalyzer new];
        
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

- (void) appendGPSInfo:(GPSLogItem*)gps
{
    CGFloat timeGap = -1;
    if (self.lastLogItem && gps.timestamp) {
        timeGap = [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp];
        if (timeGap < 0.5 && [gps.speed floatValue] < 0) {
            // 说明是重复点，忽略改点
            return;
        }
        if (![self isInTrip] && timeGap > cDriveEndThreshold*0.6) {
            _startSpeedTrace = _endSpeedTrace = 0;
            _startSpeedTraceCnt = _endSpeedTraceCnt = 0;
            _startSpeedTraceIdx = _endSpeedTraceIdx = _startMoveTraceIdx = 0;
            [self.logArr removeAllObjects];
        }
    }
    
    if (gps.timestamp)
    {
        NSDictionary * lastDate = [[BussinessDataProvider sharedInstance] lastGoodGpsItem];
        if (lastDate && [gps.timestamp timeIntervalSinceDate:lastDate[@"timestamp"]] > cOntOfDateThreshold) {
            //[self removeOldData:YES];
            _startSpeedTrace = _endSpeedTrace = 0;
            _startSpeedTraceCnt = _endSpeedTraceCnt = 0;
            _startSpeedTraceIdx = _endSpeedTraceIdx = _startMoveTraceIdx = 0;
            [self.logArr removeAllObjects];
            [self setEStat:eMotionStatGPSLost];
        }
        if ([gps.horizontalAccuracy doubleValue] < kPoorHorizontalAccuracy) {
            [[BussinessDataProvider sharedInstance] updateLastGoodGpsItem:gps];
        }
    }
    
    [self.lostGPSTimer invalidate];
    self.lostGPSTimer = nil;
    
    CGFloat speed = [gps.speed floatValue];
    CGFloat gpsAccu = [gps.horizontalAccuracy floatValue];
    NSTimeInterval interval = 0;
    if (self.lastLogItem) {
        interval = [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp];
        CGFloat dist = [gps distanceFrom:self.lastLogItem];
        if (speed < 0.1) {
            CGFloat lastAccu = [self.lastLogItem.horizontalAccuracy floatValue];
            if (interval > 5 && ((gpsAccu < kPoorHorizontalAccuracy && lastAccu < kPoorHorizontalAccuracy) || dist > 36)) {
                // if the gps signal is too low, we can not cal the speed
                CGFloat tmpSpeed = dist/interval;
                BOOL isDriving = [_isInTrip boolValue];
                if (tmpSpeed < cAvgNoiceSpeed && self.locChangeLogItem) {
                    NSTimeInterval stillDuration = [gps.timestamp timeIntervalSinceDate:self.locChangeLogItem.timestamp];
                    //NSLog(@"duration = %f, dist = %f, speed = %f, accu = %f", interval, dist, tmpSpeed, [gps.horizontalAccuracy floatValue]);
                    if (!isDriving) {
                        if (gpsAccu < kPoorHorizontalAccuracy || lastAccu < kPoorHorizontalAccuracy) {
                            if (stillDuration < 4.0*60 && (eMoveStatLine == self.moveStat || MAX(gpsAccu, lastAccu) < 60 || MIN(gpsAccu, lastAccu) < 30)) {
                                speed = tmpSpeed;
                            }
                        }
                    } else {
                        if (stillDuration < 2.0*60 || eMoveStatLine == self.moveStat || MAX(gpsAccu, lastAccu) < 60) {
                            speed = tmpSpeed;
                        }
                    }
                }
            }
        } else {
            if (interval > 5) {
                CGFloat tmpSpeed = dist/interval;
                if (tmpSpeed < speed && eMoveStatJump == self.moveStat && [gps.timestamp timeIntervalSinceDate:self.locChangeLogItem.timestamp] > 3.0*60) {
                    speed = tmpSpeed;
                }
            }
        }
    }
    
    if (speed < 0) {
        speed = 0;
    }
    if (speed > cInsDrivingSpeed*3.5 && _startMoveTraceIdx < self.logArr.count) {
        CGFloat maxAccu = MAX(gpsAccu, [self.lastLogItem.horizontalAccuracy floatValue]);
        if (maxAccu > kPoorHorizontalAccuracy) {
            speed /= 4.0;
        } else if (maxAccu > kLowHorizontalAccuracy) {
            speed /= 2.0;
        } else if (maxAccu > 60) {
            speed /= 1.5;
        }
    }
    
    DDLogWarn(@"a location is: <%.5f, %.5f>, speed=%f, accuracy=%f, origSpeed=%f", [gps.latitude floatValue], [gps.longitude floatValue], speed, [gps.horizontalAccuracy floatValue], [gps.speed floatValue]);
    
    BOOL validSpeed = YES;
    if (self.lastLogItem && speed == 0 && gpsAccu > kGoodHorizontalAccuracy && [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp] < 1) {
        validSpeed = NO;
        gps.speed = @(-1);
    }
    gps.speed = @(speed);
    
    GPSLogItem * lastGps = self.lastLogItem;
    if (validSpeed) {
        self.lastLogItem = gps;
        if (lastGps) {
            // 计算轨迹夹角，用于判断是否是正常行驶（还是gps跳变）
            if ([gps distanceFrom:lastGps] < 20) {
                // 无法估计角度，距离太近了
                gps.angle = MAXFLOAT;
            } else {
                gps.angle = [GPSOffTimeFilter angleFromPoint:[GPSOffTimeFilter coor2Point:lastGps.coordinate] toPoint:[GPSOffTimeFilter coor2Point:gps.coordinate]];
            }
            
            if (self.logArr.count > 1) {
                if (gps.angle > 10000) {
                    gps.angleDiff = -1;
                } else if (lastGps.angle > 10000) {
                    gps.angleDiff = 0;
                } else {
                    gps.angleDiff = fabsf(gps.angle - lastGps.angle);
                }
                
                NSInteger moveStatThres = 3;
                if (self.logArr.count > moveStatThres) {
                    CGFloat maxAngle = gps.angleDiff;
                    CGFloat angleDiff = gps.angleDiff;
                    NSInteger angleCnt = moveStatThres;
                    
                    NSArray * subArr = [self.logArr subarrayWithRange:NSMakeRange(self.logArr.count-angleCnt, angleCnt)];
                    NSInteger realCnt = 0;
                    for (GPSLogItem * item in subArr) {
                        maxAngle = MAX(maxAngle, item.angleDiff);
                        if (item.angleDiff >= 0) {
                            angleDiff += item.angleDiff;
                            realCnt++;
                        }
                    }
                    if (realCnt > 0) {
                        CGFloat avgAngle = angleDiff/realCnt;
                        self.moveStat = (avgAngle < 60 && maxAngle >= 0) ? eMoveStatLine : (maxAngle < 0 ? eMoveStatUnknow : eMoveStatJump);
                    } else {
                        //self.moveStat = eMoveStatUnknow;
                    }
                } else {
                    self.moveStat = eMoveStatUnknow;
                }
            
//            gps.angle = [GPSOffTimeFilter angleFromPoint:[GPSOffTimeFilter coor2Point:lastGps.coordinate] toPoint:[GPSOffTimeFilter coor2Point:gps.coordinate]];
//            if (self.logArr.count > 1) {
//                gps.angleDiff = fabsf(gps.angle - lastGps.angle);
//                
//                NSInteger moveStatThres = 3;
//                if (self.logArr.count > moveStatThres) {
//                    CGFloat maxAngle = gps.angleDiff;   // 去掉一个最大值
//                    CGFloat angleDiff = gps.angleDiff;
//                    NSInteger angleCnt = moveStatThres;
//                    NSArray * subArr = [self.logArr subarrayWithRange:NSMakeRange(self.logArr.count-angleCnt, angleCnt)];
//                    for (GPSLogItem * item in subArr) {
//                        maxAngle = MAX(maxAngle, item.angleDiff);
//                        angleDiff += item.angleDiff;
//                    }
//                    CGFloat avgAngle = (angleDiff-maxAngle)/angleCnt;
//                    self.moveStat = (avgAngle < 60 && maxAngle > 0) ? eMoveStatLine : eMoveStatJump;
//                } else {
//                    self.moveStat = eMoveStatUnknow;
//                }
            
            } else {
                self.moveStat = eMoveStatUnknow;
            }
        }

        if ([_isInTrip boolValue]) {
            [self.jamAnalyzer appendGPSInfo:gps];
        }
        // 如果靠近常用的停车位置，则把停车检测的时间阈值减少一半
        //_endThreshold = ([self.jamAnalyzer nearParkingLoc:5] ? cDriveEndThreshold*0.5 : cDriveEndThreshold);
        
        [self.logArr addObject:gps];
        
        if (speed > cInsTrafficJamSpeed) {
            _lastestNormalSpeed = gps.timestamp;
        }
    }
    
    eMotionStat stat = [self checkStatus];
    
    if ([_isInTrip boolValue]) {
        if (_driveStart) {
            CGFloat distFromStart = [gps distanceFrom:_driveStart];
            _maxDist = MAX(distFromStart, _maxDist);
        }
        if (_lastMonitorLoc) {
            CGFloat distFromMonitor = [gps distanceFromCLLocation:_lastMonitorLoc];
            _maxDist2Monitor = MAX(distFromMonitor, _maxDist2Monitor);
        }
    }
    
    if ([_isInTrip boolValue] && [gps.horizontalAccuracy doubleValue] > kLowHorizontalAccuracy) {
        if ([gps.timestamp timeIntervalSinceDate:_driveStart.timestamp] > 10*60) {
            // the car should drive at least 400 meter after start drive 10 min
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
        } else {
            if (self.lastLogItem && stat > eMotionStatStationary) {
                NSTimeInterval during = [gps.timestamp timeIntervalSinceDate:self.locChangeLogItem.timestamp];
                // the car should drive at least 400 meter after start drive 10 min
                if (during > 10*60) {
                    if (self.moveStat == eMoveStatJump) {
                        stat = eMotionStatStationary;
                        self.locChangeLogItem = gps;
                    }
                }
            }
            
        }
    }

    [self removeOldData:([self eStat]!=stat)];
    [self setEStat:stat];
    
    if (eMotionStatDriving == stat) {
        self.lostGPSTimer = [NSTimer timerWithTimeInterval:20*60 target:self selector:@selector(didLostGPS) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.lostGPSTimer forMode:NSDefaultRunLoopMode];
    } else {
        [self.jamAnalyzer driveEndAt:gps];
    }
}

- (void) removeOldData:(BOOL)force
{
    if (!force && _removeThreshold-- > 0) {
        return;
    }
    self.removeThreshold = 2;
    
    GPSLogItem * lastItem = self.lastLogItem;
    if (lastItem) {
        
        NSArray * tmpArr = self.logArr;
        NSInteger cnt = tmpArr.count;
        
        // start drive
        NSDate * thresDateSt = [lastItem.timestamp dateByAddingTimeInterval:-cDriveStartThreshold];
        for (NSInteger i = _startSpeedTraceIdx; i < cnt-cDirveStartSamplePoint; i++) {
            GPSLogItem * item = tmpArr[i];
            if ([thresDateSt compare:item.timestamp] == NSOrderedDescending) {
                _startSpeedTraceIdx = i+1;
            } else {
                CGFloat tolDist = 0;
                CGFloat tolDuration = 0;
                CGFloat tol = 0;
                NSInteger tolCnt = 0;
                GPSLogItem * tmpLast = nil;
                for (NSInteger j=i; j < cnt; j++) {
                    if (nil == tmpLast) {
                        tmpLast = tmpArr[j];
                    }
                    GPSLogItem * itemThis = tmpArr[j];
                    CGFloat thisDuration = [itemThis.timestamp timeIntervalSinceDate:tmpLast.timestamp];
                    if (thisDuration > 5) {
                        tolDist += thisDuration*[itemThis.speed floatValue];
                        tolDuration += thisDuration;
                        tmpLast = itemThis;
                    }
                    tolCnt++;
                }
                if (tolDuration > 0) {
                    tol = tolDist/tolDuration;
                }
                _startSpeedTrace = tol*tolCnt;
                _startSpeedTraceCnt = tolCnt;
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
            NSDate * thresDateEd = [lastItem.timestamp dateByAddingTimeInterval:-_endThreshold];
            for (NSInteger i = _endSpeedTraceIdx; i < cnt-cDirveEndSamplePoint; i++) {
                GPSLogItem * item = tmpArr[i];
                if ([thresDateEd compare:item.timestamp] == NSOrderedDescending) {
                    _endSpeedTraceIdx = i+1;
                } else {
                    CGFloat tolDist = 0;
                    CGFloat tolDuration = 0;
                    CGFloat tol = 0;
                    NSInteger tolCnt = 0;
                    GPSLogItem * tmpLast = nil;
                    for (NSInteger j=i; j < cnt; j++) {
                        if (nil == tmpLast) {
                            tmpLast = tmpArr[j];
                        }
                        GPSLogItem * itemThis = tmpArr[j];
                        CGFloat thisDuration = [itemThis.timestamp timeIntervalSinceDate:tmpLast.timestamp];
                        if (thisDuration > 5) {
                            tolDist += thisDuration*[itemThis.speed floatValue];
                            tolDuration += thisDuration;
                            tmpLast = itemThis;
                        }
                        tolCnt++;
                    }
                    if (tolDuration > 0) {
                        tol = tolDist/tolDuration;
                    }
                    _endSpeedTrace = tol*tolCnt;
                    _endSpeedTraceCnt = tolCnt;
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


- (CGFloat) avgSpeedFromDate:(NSDate*)fromDate minSampleCnt:(NSInteger)minCnt
{
    NSArray * tmpArr = self.logArr;
    NSInteger tolCnt = tmpArr.count;
    
    if (tolCnt < minCnt) {
        return -1;
    }

    __block NSInteger cnt = 0;
    __block CGFloat tolSpeed = 0;
    [tmpArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(GPSLogItem * obj, NSUInteger idx, BOOL *stop) {
        if ([fromDate compare:obj.timestamp] == NSOrderedAscending) {
            CGFloat speed = [obj.speed floatValue];
            if (speed >= 0) {
                tolSpeed += speed;
                cnt++;
            }
        } else {
            *stop = 0;
        }
    }];
    
    if (cnt < minCnt) {
        return -1;
    }
    return tolSpeed/cnt;
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
        CGFloat maxDist = _maxDist;
        CGFloat maxDist2Monitor = _maxDist2Monitor;
        if (inTrip) {
            if (_startMoveTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_startMoveTraceIdx]));
                _driveStart = item;
                GPSEventItem * lastMonitorRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:item.timestamp ofType:eGPSEventMonitorRegion];
                if (lastMonitorRegion) {
                    _lastMonitorLoc = [lastMonitorRegion location];
                }
                _maxDist2Monitor = 0;
                _maxDist = 0;
            }
        } else {
            if (_endSpeedTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
                if (_maxDist > 0 && _maxDist < 400 && _maxDist2Monitor > 0 && _maxDist2Monitor < 400) {
                    dropTrip = YES;
                }
            }
            _maxDist = 0;
            _maxDist2Monitor = 0;
            _driveStart = nil;
            _lastMonitorLoc = nil;
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

        DDLogWarn(@"!!!!!!!!!!!!!!!!!!!!!!!! notify is driving %d at %@, if drop %d, maxDist %f,%f", inTrip, item.timestamp, dropTrip, maxDist, maxDist2Monitor);
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
        self.locChangeLogItem = nil;
    }
    else if (isInTrip && (eStat < eMotionStatWalking))
    {
        [self setIsInTrip:NO];
        
        // if the trip change from drive to stationary, reset all data to prevent cumulate error
        _startSpeedTrace = _endSpeedTrace = 0;
        _startSpeedTraceCnt = _endSpeedTraceCnt = 0;
        _startSpeedTraceIdx = _endSpeedTraceIdx = _startMoveTraceIdx = 0;
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
            DDLogWarn(@"$$$$$$$$$$$$$$$$$$$$$ start speed = %f - %ld", avgSpeed, (long)newStat);
        }
    } else {
        // fast decide using M7 chrip
        LocationTracker * tracker = ((AppDelegate*)([UIApplication sharedApplication].delegate)).locationTracker;
        _endThreshold = cDriveEndThreshold;
        if (_lastestNormalSpeed && [[NSDate date] timeIntervalSinceDate:_lastestNormalSpeed] >= 20) {
            NSTimeInterval driveDuring = [tracker duringForAutomationWithin:60];
            if (driveDuring > 5) {
                _endSpeedTrace = 0;
                _endSpeedTraceCnt = 0;
                _endSpeedTraceIdx = self.logArr.count-1;
                return eMotionStatDriving;
            }
            // 如果开车时，正在使用或者路况不好造成颠簸
            else if (0 == driveDuring && [tracker duringForWalkRunWithin:60] > 30 && !tracker.rawMotionActivity.automotive) {
                _endThreshold = cDriveEndThreshold/2.0f;
                NSTimeInterval interval = [self.lastLogItem.timestamp timeIntervalSinceDate:self.locChangeLogItem.timestamp];
                if (interval > 3*60) {
                    DDLogWarn(@"&&&&&&&&&&&&& motion regard as drive stop &&&&&&&&&&&&& ");
                    _endSpeedTrace = 0;
                    _endSpeedTraceCnt = 0;
                    _endSpeedTraceIdx = self.logArr.count-1;
                    return eMotionStatStationary;
                }
            }
        }
        if (_endSpeedTraceCnt > cDirveEndSamplePoint && _endSpeedTraceIdx < self.logArr.count) {
            GPSLogItem * item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
            if ([[NSDate date] timeIntervalSinceDate:item.timestamp] >= _endThreshold*0.6) {
                CGFloat avgSpeed = _endSpeedTrace/_endSpeedTraceCnt;
                if (avgSpeed  < cAvgStationarySpeed && [tracker duringForAutomationWithin:60] < 30) {
                    newStat = eMotionStatStationary;
                } else if (avgSpeed  < cAvgWalkingSpeed) {
                    newStat = eMotionStatWalking;
                } else if (avgSpeed  < cAvgRunningSpeed) {
                    newStat = eMotionStatRunning;
                } else {
                    newStat = eMotionStatDriving;
                }
                DDLogWarn(@"$$$$$$$$$$$$$$$$$$$$$ end speed = %f - %ld", avgSpeed, (long)newStat);
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
