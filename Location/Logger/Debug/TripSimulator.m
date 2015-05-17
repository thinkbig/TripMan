//
//  TripSimulator.m
//  TripMan
//
//  Created by taq on 4/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripSimulator.h"
#import "GPSOffTimeFilter.h"
#import "GPSAnalyzerRealTime.h"

//#define NSLog(...) {}

@interface TripSimulator () {
    
    CGFloat     _startSpeedTrace;
    NSInteger   _startSpeedTraceCnt;
    NSInteger   _startSpeedTraceIdx;

    NSInteger   _startMoveTraceIdx;
    
    CGFloat     _endSpeedTrace;
    NSInteger   _endSpeedTraceCnt;
    NSInteger   _endSpeedTraceIdx;
    
    NSDate *    _lastestNormalSpeed;
    
    NSNumber *          _isInTrip;
    NSNumber *          _eStat;
    NSDate *            _lastExitReagionDate;
    
    GPSLogItem *        _driveStart;
    CGFloat             _maxDist;
    
    CGFloat             _endThreshold;
    
}

@property (nonatomic, strong) NSMutableArray *          logArr;
@property (nonatomic, strong) GPSLogItem *              lastLogItem;
@property (nonatomic, strong) GPSLogItem *              locChangeLogItem;
@property (nonatomic) NSInteger                         removeThreshold;
@property (nonatomic) eMoveStat moveStat;     // 是否是线性移动，还是gps不稳定跳动，根据最近的N（目前为10）个gps点的运动规律

@end


@implementation TripSimulator

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
    }
    return self;
}

- (void) setExitRegion:(NSDate*)exitDate {
    _lastExitReagionDate = exitDate;
}

- (void)setGpsLogs:(NSArray *)gpsLogs {
    _gpsLogs = gpsLogs;
    for (GPSLogItem * item in gpsLogs) {
        [self appendGPSInfo:item];
    }
}

- (void) appendGPSInfo:(GPSLogItem*)gps
{
    if (self.lastLogItem && [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp] < 0.5 && [gps.speed floatValue] < 0) {
        // 说明是重复点，忽略改点
        return;
    }
    
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
                NSLog(@"################ cal Speed = %f, %lu", tmpSpeed, self.moveStat);
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
                NSLog(@"$$$$$$$$$$$$$$$$ cal Speed = %f", tmpSpeed);
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
    
    NSLog(@"%@ speed = %f <%.5f,%.5f>", gps.timestamp, speed, [gps.latitude floatValue], [gps.longitude floatValue]);
    if (_maxSpeed < speed) {
        _maxSpeed = speed;
    }
    
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
                        self.moveStat = eMoveStatUnknow;
                    }
                } else {
                    self.moveStat = eMoveStatUnknow;
                }
                
//                gps.angle = [GPSOffTimeFilter angleFromPoint:[GPSOffTimeFilter coor2Point:lastGps.coordinate] toPoint:[GPSOffTimeFilter coor2Point:gps.coordinate]];
//                if (self.logArr.count > 1) {
//                    gps.angleDiff = fabsf(gps.angle - lastGps.angle);
//                    
//                    NSInteger moveStatThres = 3;
//                    if (self.logArr.count > moveStatThres) {
//                        CGFloat maxAngle = gps.angleDiff;   // 去掉一个最大值
//                        CGFloat angleDiff = gps.angleDiff;
//                        NSInteger angleCnt = moveStatThres;
//                        
//                        NSArray * subArr = [self.logArr subarrayWithRange:NSMakeRange(self.logArr.count-angleCnt, angleCnt)];
//                        for (GPSLogItem * item in subArr) {
//                            maxAngle = MAX(maxAngle, item.angleDiff);
//                            angleDiff += item.angleDiff;
//                        }
//                        CGFloat avgAngle = (angleDiff-maxAngle)/angleCnt;
//                        self.moveStat = (avgAngle < 60 && maxAngle > 0) ? eMoveStatLine : eMoveStatJump;
//                    } else {
//                        self.moveStat = eMoveStatUnknow;
//                    }

            } else {
                self.moveStat = eMoveStatUnknow;
            }
        }

        [self.logArr addObject:gps];
        
        if (speed > cInsTrafficJamSpeed) {
            _lastestNormalSpeed = gps.timestamp;
        }
    }
    
    eMotionStat stat = [self checkStatus];
    
    if (eMotionStatDriving == stat) {
        if (_driveStart) {
            CGFloat distFromStart = [gps distanceFrom:_driveStart];
            _maxDist = MAX(distFromStart, _maxDist);
        } else {
            _driveStart = gps;
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
            if (self.locChangeLogItem && stat > eMotionStatStationary) {
                NSTimeInterval during = [gps.timestamp timeIntervalSinceDate:self.locChangeLogItem.timestamp];
                // the car should drive at least 400 meter after start drive 10 min
                if (during > 10*60) {
                    if (self.moveStat == eMoveStatJump) {
                        stat = eMotionStatStationary;
                    }
                    self.locChangeLogItem = gps;
                }
            }
            
        }
    }
    
    [self removeOldData:([self eStat]!=stat)];
    [self setEStat:stat];
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
                            //NSLog(@"%ld, <%.5f,%.5f> = %f*%f, %@", j, [itemThis.latitude floatValue], [itemThis.longitude floatValue], [itemThis.speed floatValue], thisDuration, itemThis.timestamp);
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

- (BOOL)isInTrip
{
    if (_isInTrip) {
        return [_isInTrip boolValue];
    }
    return NO;
}

- (void)setIsInTrip:(BOOL)inTrip
{
    if (nil == _isInTrip || inTrip != [_isInTrip boolValue]) {
        _isInTrip = @(inTrip);
        
        __block GPSLogItem * item = nil;
        BOOL dropTrip = NO;
        if (inTrip) {
            if (_startMoveTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_startMoveTraceIdx]));
                _driveStart = item;
                _maxDist = 0;
            }
        } else {
            if (_endSpeedTraceIdx < self.logArr.count) {
                item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
                if (_maxDist > 0 && _maxDist < 400) {
                    dropTrip = YES;
                }
            }
            _maxDist = 0;
            _driveStart = nil;
        }
        
        NSLog(@"!!!!!!!!!!!!!!! drive stat change to %d", inTrip);
        if (self.delegate) {
            if (inTrip) {
                [self.delegate tripSimulator:self tripDidStart:item];
            } else {
                [self.delegate tripSimulator:self tripDidEnd:item shouldDrop:dropTrip];
            }
        }
    }
}

- (eMotionStat)eStat
{
    if (_eStat) {
        return (eMotionStat)[_eStat integerValue];
    }
    return eMotionStatGPSLost;
}

- (void)setEStat:(eMotionStat)eStat
{
    if (nil == _eStat || [_eStat integerValue] != eStat) {
        _eStat = @(eStat);
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
    eMotionStat newStat = [self eStat];
    if (![self isInTrip]) {
        // check if start driving
        if (_startSpeedTraceCnt >= cDirveStartSamplePoint) {
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
        if (_endSpeedTraceCnt >= cDirveEndSamplePoint && _endSpeedTraceIdx < self.logArr.count) {
            GPSLogItem * item = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
            GPSLogItem * lastItem = ((GPSLogItem*)([self.logArr lastObject]));
            if ([lastItem.timestamp timeIntervalSinceDate:item.timestamp] >= _endThreshold*0.6) {
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

@end
