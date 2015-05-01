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
        self.removeThreshold = 20;
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
    if (self.lastLogItem && fabsf([self.lastLogItem.speed floatValue] - [gps.speed floatValue]) < 0.0001 && [self.lastLogItem distanceFrom:gps] == 0) {
        // 说明是重复点，忽略改点
        return;
    }

    CGFloat accu = [gps.horizontalAccuracy doubleValue];
    
    CGFloat speed = [gps.speed floatValue] < 0 ? 0 : [gps.speed floatValue];
    if (![_isInTrip boolValue]) {
        if (speed > cInsDrivingSpeed && _startMoveTraceIdx < self.logArr.count) {
            GPSLogItem * firstItem = self.logArr[_startMoveTraceIdx];
            CGFloat dist = [gps distanceFrom:firstItem];
            if (accu > kLowHorizontalAccuracy && dist < 500) {
                speed /= 2.0;
            } else {
                if (speed > cInsDrivingSpeed * 2) {
                    if (_startSpeedTraceCnt >= cDirveStartSamplePoint) {
                        CGFloat avgSpeed = _startSpeedTrace/_startSpeedTraceCnt;
                        if (avgSpeed * 6 < speed) {
                            speed /= 3.0;
                        } else if (avgSpeed * 4 < speed) {
                            speed /= 2.0;
                        }
                    } else {
                        speed /= 2.0;
                    }
                }
            }
            speed = MIN(speed, cInsDrivingSpeed*2.0);
        }
    } else if (speed > cInsDrivingSpeed * 3) {
        CGFloat avgSpeed = _startSpeedTrace/_startSpeedTraceCnt;
        if (_startSpeedTraceCnt >= cDirveStartSamplePoint) {
            if (avgSpeed < 2) {
                if (avgSpeed * 6 < speed) {
                    speed /= 3.0;
                }
            } else {
                if (avgSpeed * 6 < speed) {
                    speed /= 3.0;
                } else if (avgSpeed * 4 < speed) {
                    speed /= 2.0;
                }
            }
            speed = MIN(speed, cInsDrivingSpeed*2.0);
        } else {
            speed = MIN(speed, avgSpeed*3.0);
        }
    }
    
    if (_maxSpeed < speed) {
        _maxSpeed = speed;
    }
    
    BOOL validSpeed = YES;
    if (self.lastLogItem && speed == 0 && accu > kGoodHorizontalAccuracy && [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp] < 1) {
        validSpeed = NO;
        gps.speed = @(-1);
    }
    gps.speed = @(speed);
    
    GPSLogItem * lastGps = self.lastLogItem;
    if (validSpeed) {
        _startSpeedTrace += speed;
        _startSpeedTraceCnt++;
        _endSpeedTrace += speed;
        _endSpeedTraceCnt++;
        
        self.lastLogItem = gps;
        if (lastGps) {
            // 计算轨迹夹角，用于判断是否是正常行驶（还是gps跳变）
            gps.angle = [GPSOffTimeFilter angleFromPoint:[GPSOffTimeFilter coor2Point:lastGps.coordinate] toPoint:[GPSOffTimeFilter coor2Point:gps.coordinate]];
            if (self.logArr.count > 1) {
                gps.angleDiff = fabsf(gps.angle - lastGps.angle);
                
                if (self.logArr.count > 10) {
                    CGFloat maxAngle = gps.angleDiff;   // 去掉一个最大值
                    CGFloat angleDiff = gps.angleDiff;
                    NSInteger angleCnt = 10;
                    NSArray * subArr = [self.logArr subarrayWithRange:NSMakeRange(self.logArr.count-angleCnt, angleCnt)];
                    for (GPSLogItem * item in subArr) {
                        maxAngle = MAX(maxAngle, item.angleDiff);
                        angleDiff += item.angleDiff;
                    }
                    CGFloat avgAngle = (angleDiff-maxAngle)/angleCnt;
                    self.moveStat = (avgAngle < 60 && maxAngle > 0) ? eMoveStatLine : eMoveStatJump;
                } else {
                    self.moveStat = eMoveStatUnknow;
                }
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
            if (self.lastLogItem && stat > eMotionStatStationary) {
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
    self.removeThreshold = 7;
    
    GPSLogItem * lastItem = self.lastLogItem;
    if (lastItem) {
        
        NSArray * tmpArr = self.logArr;
        NSInteger cnt = tmpArr.count;
        
        // start drive
        NSDate * thresDateSt = [lastItem.timestamp dateByAddingTimeInterval:-cDriveStartThreshold];
        for (NSInteger i = _startSpeedTraceIdx; i < cnt-cDirveStartSamplePoint; i++) {
            GPSLogItem * item = tmpArr[i];
            if ([thresDateSt compare:item.timestamp] == NSOrderedDescending) {
                _startSpeedTrace -= ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
                _startSpeedTraceCnt--;
                _startSpeedTraceIdx = i+1;
            } else {
                //_startSpeedTraceIdx = i;
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
                    _endSpeedTrace -= ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
                    _endSpeedTraceCnt--;
                    _endSpeedTraceIdx = i+1;
                } else {
                    //_endSpeedTraceIdx = i+1;
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
        }
    } else {
        if (_endSpeedTraceCnt > cDirveEndSamplePoint && _endSpeedTraceIdx < self.logArr.count) {
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
            }
        }
    }
    return newStat;
}

@end
