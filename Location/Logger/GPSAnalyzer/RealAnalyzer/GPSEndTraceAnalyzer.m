//
//  GPSEndTraceAnalyzer.m
//  Location
//
//  Created by taq on 10/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSEndTraceAnalyzer.h"
#import "GPSLogger.h"

@interface GPSEndTraceAnalyzer () {
    
    CGFloat         _endSpeedTrace;
    NSInteger       _endSpeedTraceCnt;
    NSInteger       _endSpeedTraceIdx;

}

@property (nonatomic, strong) GPSLogItem *              lastLogItem;
@property (nonatomic, strong) NSMutableArray *          logArr;

@end


@implementation GPSEndTraceAnalyzer

- (id)init
{
    self = [super init];
    if (self) {
        self.logArr = [NSMutableArray array];
    }
    return self;
}

- (void) reset
{
    _endSpeedTrace = 0;
    _endSpeedTraceCnt = 0;
    _endSpeedTraceIdx = 0;
    self.lastLogItem = nil;
    [self.logArr removeAllObjects];
}

- (GPSLogItem*) traceGPSEndWithArray:(NSArray*)gpsArray
{
    for (GPSLogItem * item in gpsArray) {
        GPSLogItem * endItem = [self traceGPSEndWithItem:item];
        if (endItem) {
            return endItem;
        }
    }
    return nil;
}

- (GPSLogItem*) traceGPSEndWithItem:(GPSLogItem*)gps
{
    GPSLogItem * endItem = nil;
    if (gps.timestamp)
    {
        if (self.lastLogItem && [gps.timestamp timeIntervalSinceDate:self.lastLogItem.timestamp] > cOntOfDateThreshold) {
            endItem = self.lastLogItem;
            [self reset];
        }
    }
    
    CGFloat speed = [gps.speed floatValue] < 0 ? 0 : [gps.speed floatValue];
    _endSpeedTrace += speed;
    _endSpeedTraceCnt++;
    
    BOOL readyCheck = NO;
    if (self.logArr.count > 0) {
        GPSLogItem * first = self.logArr[0];
        NSTimeInterval during = [gps.timestamp timeIntervalSinceDate:first.timestamp];
        if (during > cDriveEndThreshold) {
            readyCheck = YES;
        }
    }

    self.lastLogItem = gps;
    [self.logArr addObject:gps];
    
    if (readyCheck) {
        eMotionStat stat = [self checkStatus];
        [self removeOldData];
        
        if (eMotionStatStationary == stat) {
            endItem = ((GPSLogItem*)(self.logArr[_endSpeedTraceIdx]));
            [self reset];
        }
    }

    return endItem;
}

- (eMotionStat) checkStatus
{
    eMotionStat newStat = eMotionStatDriving;
    if (_endSpeedTraceCnt > cDirveEndSamplePoint) {
        CGFloat avgSpeed = _endSpeedTrace/_endSpeedTraceCnt;
        if (avgSpeed  < cAvgStationarySpeed) {
            newStat = eMotionStatStationary;
        } else if (avgSpeed  < cAvgWalkingSpeed) {
            newStat = eMotionStatWalking;
        } else if (avgSpeed  < cAvgRunningSpeed) {
            newStat = eMotionStatRunning;
        }
    }
    return newStat;
}

- (void) removeOldData
{
    GPSLogItem * lastItem = self.lastLogItem;
    if (lastItem) {
        
        NSArray * tmpArr = self.logArr;
        NSInteger cnt = tmpArr.count;

        // end drive
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

@end
