//
//  GPSOffTimeFilter.m
//  Location
//
//  Created by taq on 9/29/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSOffTimeFilter.h"
#import "GPSLogItem.h"

#define ANGLE(r)   (180.0*(r)/M_PI)

@implementation GPSTurningItem

- (id)initWithInstSpeed:(CGFloat)speed
{
    self = [super init];
    if (self) {
        self.instSpeed = speed;
        self.eStat = eTurningUnknow;
        self.angle = 0;
        self.distAfterTurning = 0;
        self.duringAfterTurning = 0;
    }
    return self;
}

- (NSString *)description
{
    NSString * stat = @"Unknow";
    switch (self.eStat) {
        case eTurningLeft:
            stat = @"TurningLeft";
            break;
        case eTurningRight:
            stat = @"TurningRight";
            break;
        case eTurningAround:
            stat = @"TurningAround";
            break;
        case eTurningStart:
            stat = @"TurningStart";
            break;
        case eTurningEnd:
            stat = @"TurningEnd";
            break;
            
        default:
            break;
    }
    return [stat stringByAppendingFormat:@", speed=%f, angle=%f, distAfter=%f, duringAfter=%f", self.instSpeed, self.angle, self.distAfterTurning, self.duringAfterTurning];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////

@interface GPSOffTimeFilter ()

@property (nonatomic, strong) NSArray *                     smoothData;
@property (nonatomic, strong) NSMutableArray *              anglePointIdx;

@end

@implementation GPSOffTimeFilter

+ (NSArray*) smoothGPSData:(NSArray*)gpsData iteratorCnt:(NSInteger)repeat
{
    if (repeat <= 0) {
        return gpsData;
    }
    NSMutableArray * smoothData = [NSMutableArray arrayWithCapacity:gpsData.count];
    NSMutableArray * penddingData = [NSMutableArray arrayWithCapacity:8];
    
    for (GPSLogItem * item in gpsData)
    {
        CGFloat accuracy = [item.horizontalAccuracy doubleValue];
        if (accuracy < 0 || accuracy > 100) {
            continue;
        }
        if (accuracy < 30) {
            // regard as good location
            if (penddingData.count == 1) {
                if (smoothData.count > 0) {
                    GPSLogItem * newItem = [self smoothItem:@[[smoothData lastObject], item]];
                    [smoothData addObject:newItem];
                }
            } else if (penddingData.count > 1) {
                GPSLogItem * newItem = [self smoothItem:penddingData];
                [smoothData addObject:newItem];
            }
            [penddingData removeAllObjects];
            [smoothData addObject:item];
            continue;
        } else {
            [penddingData addObject:item];
            NSInteger thresHold = 2;
            if (penddingData.count >= thresHold) {
                GPSLogItem * newItem = [self smoothItem:penddingData];
                [smoothData addObject:newItem];
                [penddingData removeAllObjects];
            }
        }
    }
    
    return [self smoothGPSData:smoothData iteratorCnt:repeat-1];
}

+ (GPSLogItem*) smoothItem:(NSArray*)itemArr
{
    GPSLogItem * newItem = nil;
    CGFloat allAccu = 0;
    for (GPSLogItem * penddingItem in itemArr) {
        CGFloat accuracy = [penddingItem.horizontalAccuracy doubleValue];
        if (accuracy < 0) {
            accuracy = 100;
        } else if (accuracy == 0) {
            accuracy = 0.1;
        }
        if (nil == newItem || [newItem.horizontalAccuracy doubleValue] > accuracy) {
            newItem = penddingItem;
        }
        allAccu += 1.0/accuracy;
    }
    
    CGFloat lat = 0;
    CGFloat lon = 0;
    for (GPSLogItem * penddingItem in itemArr) {
        CGFloat accuracy = [penddingItem.horizontalAccuracy doubleValue];
        if (accuracy < 0) {
            accuracy = 100;
        } else if (accuracy == 0) {
            accuracy = 0.1;
        }
        CGFloat accuPer = (1.0/accuracy)/allAccu;
        lat += [penddingItem.latitude doubleValue]*accuPer;
        lon += [penddingItem.longitude doubleValue]*accuPer;
    }
    newItem.latitude = @(lat);
    newItem.longitude = @(lon);
    
    return newItem;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

+ (CGFloat) dist2FromPoint:(CGPoint)fromPt toPoint:(CGPoint)toPt
{
    return (toPt.x-fromPt.x)*(toPt.x-fromPt.x) + (toPt.y-fromPt.y)*(toPt.y-fromPt.y);
}

+ (CGFloat) dist2FromGPSItem:(GPSLogItem*)fromItem toItem:(GPSLogItem*)toItem
{
    return [[fromItem location] distanceFromLocation:[toItem location]];
}

+ (CGPoint)item2Point:(GPSLogItem*)item
{
    return CGPointMake([item.latitude doubleValue]*1000000, [item.longitude doubleValue]*1000000);
}

+ (CGFloat) angleFromPoint:(CGPoint)fromPt toPoint:(CGPoint)toPt
{
    CGFloat dx = toPt.x - fromPt.x;
    CGFloat dy = -(toPt.y - fromPt.y);
    
    CGFloat angle = 0;
    if (0 == dx) {
        if (dy > 0) {
            angle = 90;
        } else {
            angle = -90;
        }
    } else {
        angle = ANGLE(atan(dy/dx));
        if (dx < 0) {
            if (dy > 0) {
                angle = 180 + angle;
            } else {
                angle = -(180 - angle);
            }
        }
    }
    return angle;
}

- (CGFloat)checkPotinAngle:(CGPoint)pt1 antPt:(CGPoint)pt2 antPt:(CGPoint)pt3
{
    CGFloat angle1 = [GPSOffTimeFilter angleFromPoint:pt1 toPoint:pt2];
    CGFloat angle2 = [GPSOffTimeFilter angleFromPoint:pt2 toPoint:pt3];
    
    CGFloat angleD = fabs(angle2 - angle1);
    angleD = angleD > 180 ? 360-angleD : angleD;
    
    //NSLog(@"angle1 = %f, angle2 = %f, angleD = %f", angle1, angle2, angleD);
    
    return angleD;
}

// >0 means left turn, <0 means right turn, 0 means no turn
- (NSInteger)checkTurningDir:(CGPoint)pt1 antPt:(CGPoint)pt2 antPt:(CGPoint)pt3
{
    return (pt3.x-pt1.x)*(pt2.y-pt1.y) - (pt2.x-pt1.x)*(pt3.y-pt1.y);
}

- (NSInteger)featurePointWithIdx:(NSInteger)firstIdx andPt:(NSInteger)secondIdx
{
    GPSLogItem * firstItem = self.smoothData[firstIdx];
    GPSLogItem * secondItem = self.smoothData[secondIdx];

    CGPoint firstPt = [GPSOffTimeFilter item2Point:firstItem];
    CGPoint secondPt = [GPSOffTimeFilter item2Point:secondItem];
    
    CGFloat dist = [GPSOffTimeFilter dist2FromPoint:firstPt toPoint:secondPt];
    
    CGFloat maxDist = 0;
    CGPoint maxPt = CGPointZero;
    GPSLogItem * maxItem = nil;
    NSInteger featureIdx = -1;
    
    if (dist <= powf(30, 2)) {
        return featureIdx;
    }
    
    CGFloat a = secondPt.y - firstPt.y;
    CGFloat b = firstPt.x - secondPt.x;
    CGFloat c = -firstPt.x*(secondPt.y-firstPt.y) + firstPt.y*(secondPt.x-firstPt.x);
    CGFloat a2b2 = a*a + b*b;
    
    for (long i = firstIdx+1; i < secondIdx; i++) {
        CGPoint curPt = [GPSOffTimeFilter item2Point:self.smoothData[i]];
        CGFloat curDist = powf(curPt.x*a+curPt.y*b+c, 2)/a2b2;
        if (curDist > maxDist) {
            maxDist = curDist;
            maxPt = curPt;
            maxItem = self.smoothData[i];
            featureIdx = i;
        }
    }
    
    if (maxItem) {
        CGFloat dist1 = [GPSOffTimeFilter dist2FromGPSItem:firstItem toItem:maxItem];
        CGFloat dist2 = [GPSOffTimeFilter dist2FromGPSItem:maxItem toItem:secondItem];
        if (dist1 < 100 && dist2 < 100) {
            // if all distance is less than 100m, remove the angle point
            featureIdx = -1;
        } else if ((dist1 < 200 && dist2 < 200) && [self checkPotinAngle:firstPt antPt:maxPt antPt:secondPt] < 60) {
            // if all distance is less than 200m, check the angle
            featureIdx = -1;
        } else if (dist1 < 20 || dist2 < 20) {
            // if one distence is less than 20m, remove this line
            featureIdx = -1;
        } else if ((dist1*5 < dist2 || dist2*5 < dist1) && (dist1 < 60 || dist2 < 60)) {
            // the distance is within 5 times, and the shortest is less than 60m
            featureIdx = -1;
        } else if ([self checkPotinAngle:firstPt antPt:maxPt antPt:secondPt] < 10) {
            // all else if the angle is less than 10 degree
            featureIdx = -1;
        }
    }
    
    if (featureIdx > 0) {
        return featureIdx;
    }
    
    return -1;
}

- (void)_calFeaturePointsAtIdx:(NSInteger)idx
{
    if (idx+1 < self.anglePointIdx.count)
    {
        NSInteger firstIdx = [self.anglePointIdx[idx] integerValue];
        NSInteger secondIdx = [self.anglePointIdx[idx+1] integerValue];
        
        NSInteger featureIdx = [self featurePointWithIdx:firstIdx andPt:secondIdx];
        
        if (featureIdx >= 0) {
            [self.anglePointIdx insertObject:@(featureIdx) atIndex:idx+1];
            [self _calFeaturePointsAtIdx:idx];
        } else {
            [self _calFeaturePointsAtIdx:idx+1];
        }
    }
}

- (void)_filterFeaturePointsAtIdx:(NSInteger)idx
{
    if (idx+2 < self.anglePointIdx.count)
    {
        NSInteger idx1 = [self.anglePointIdx[idx] integerValue];
        NSInteger idx2 = [self.anglePointIdx[idx+1] integerValue];
        NSInteger idx3 = [self.anglePointIdx[idx+2] integerValue];
        
        if ([self checkPotinAngle:[GPSOffTimeFilter item2Point:self.smoothData[idx1]] antPt:[GPSOffTimeFilter item2Point:self.smoothData[idx2]] antPt:[GPSOffTimeFilter item2Point:self.smoothData[idx3]]] > 15) {
            [self _filterFeaturePointsAtIdx:idx+1];
        } else {
            [self.anglePointIdx removeObjectAtIndex:idx+1];
            [self _filterFeaturePointsAtIdx:idx];
        }
    }
}

- (void) calGPSDataForTurning:(NSArray*)gpsData smoothFirst:(BOOL)smooth
{
    self.smoothData = gpsData;
    if (smooth) {
        self.smoothData = [GPSOffTimeFilter smoothGPSData:gpsData iteratorCnt:3];
    }
    self.anglePointIdx = [NSMutableArray array];
    if (self.smoothData.count > 0)
    {
        [self.anglePointIdx addObject:@0];
        if (self.smoothData.count > 1) {
            [self.anglePointIdx addObject:@(self.smoothData.count-1)];
        }
        
        [self _calFeaturePointsAtIdx:0];
        [self _filterFeaturePointsAtIdx:0];
    }
}

- (NSArray*)featurePointIndex
{
    return self.anglePointIdx;
}

- (NSArray*)featurePoints
{
    if (self.smoothData.count > 0 && self.anglePointIdx.count > 0)
    {
        NSMutableArray * ptArr = [[NSMutableArray alloc] initWithCapacity:self.anglePointIdx.count];
        for (NSNumber * num in self.anglePointIdx) {
            NSValue * ptVal = [self.smoothData objectAtIndex:[num integerValue]];
            [ptArr addObject:ptVal];
        }
        return ptArr;
    }
    return nil;
}

- (NSArray*)turningParams
{
    NSArray * gpsLogs = [self featurePoints];
    NSArray * logIdx = [self featurePointIndex];
    if (gpsLogs.count <= 0) {
        return nil;
    } else if (gpsLogs.count == 1) {
        GPSTurningItem * turningItem = [[GPSTurningItem alloc] initWithInstSpeed:[((GPSLogItem*)gpsLogs[0]).speed doubleValue]];
        return @[turningItem];
    }
    
    NSMutableArray * turningArr = [NSMutableArray arrayWithCapacity:gpsLogs.count];
    GPSLogItem * firstItem = (GPSLogItem*)gpsLogs[0];
    GPSLogItem * secondItem = (GPSLogItem*)gpsLogs[1];
    
    GPSTurningItem * first = [[GPSTurningItem alloc] initWithInstSpeed:[firstItem.speed doubleValue]];
    first.eStat = eTurningStart;
    first.duringAfterTurning = [secondItem.timestamp timeIntervalSinceDate:firstItem.timestamp];
    first.distAfterTurning = [GPSOffTimeFilter dist2FromGPSItem:firstItem toItem:secondItem];
    [turningArr addObject:first];
    
    for (NSInteger i = 1; i < gpsLogs.count-1; i++)
    {
        GPSLogItem * prevItem = (GPSLogItem*)gpsLogs[i-1];
        GPSLogItem * item = (GPSLogItem*)gpsLogs[i];
        GPSLogItem * nextItem = (GPSLogItem*)gpsLogs[i+1];
        
        GPSTurningItem * turning = [[GPSTurningItem alloc] initWithInstSpeed:[item.speed doubleValue]];
        turning.duringAfterTurning = [nextItem.timestamp timeIntervalSinceDate:item.timestamp];
        turning.distAfterTurning = [GPSOffTimeFilter dist2FromGPSItem:item toItem:nextItem];
        turning.angle = [self checkPotinAngle:[GPSOffTimeFilter item2Point:prevItem] antPt:[GPSOffTimeFilter item2Point:item] antPt:[GPSOffTimeFilter item2Point:nextItem]];
        turning.instSpeed = [item.speed doubleValue] < 0 ? 0 : [item.speed doubleValue];
        NSInteger turnDir = [self checkTurningDir:[GPSOffTimeFilter item2Point:prevItem] antPt:[GPSOffTimeFilter item2Point:item] antPt:[GPSOffTimeFilter item2Point:nextItem]];
        if (turning.angle > 170 || turnDir == 0) {
            turning.eStat = eTurningAround;
        } else if (turnDir < 0) {
            turning.eStat = eTurningRight;
        } else if (turnDir > 0) {
            turning.eStat = eTurningLeft;
        }
        
        // find prev
        CGFloat tolSpeed = 0;
        CGFloat maxSpeed = 0;
        CGFloat speedCnt = 0;
        
        NSInteger turnBegin = ([logIdx[i-1] integerValue] + [logIdx[i] integerValue])/2.0;
        for (NSInteger j = [logIdx[i] integerValue]; j > turnBegin; j--) {
            GPSLogItem * lastItem = (GPSLogItem*)self.smoothData[j];
            CGFloat lastSpeed = [lastItem.speed doubleValue] < 0 ? 0 : [lastItem.speed doubleValue];
            CGFloat dist = [GPSOffTimeFilter dist2FromGPSItem:item toItem:lastItem];
            CGFloat during = fabs([item.timestamp timeIntervalSinceDate:lastItem.timestamp]);
            if (during < 10 || dist < 50) {
                tolSpeed += lastSpeed;
                speedCnt++;
                maxSpeed = MAX(lastSpeed, maxSpeed);
            } else if (during > 10 && dist > 50) {
                break;
            }
        }
        
        NSInteger turnEnd = ([logIdx[i+1] integerValue] + [logIdx[i] integerValue])/2.0;
        for (NSInteger j = [logIdx[i] integerValue]; j <= turnEnd; j++) {
            GPSLogItem * lastItem = (GPSLogItem*)self.smoothData[j];
            CGFloat lastSpeed = [lastItem.speed doubleValue] < 0 ? 0 : [lastItem.speed doubleValue];
            CGFloat dist = [GPSOffTimeFilter dist2FromGPSItem:item toItem:lastItem];
            CGFloat during = fabs([item.timestamp timeIntervalSinceDate:lastItem.timestamp]);
            if (during < 5 || dist < 50) {
                tolSpeed += lastSpeed;
                speedCnt++;
                maxSpeed = MAX(lastSpeed, maxSpeed);
            } else if (during > 5 && dist > 50) {
                break;
            }
        }
        
        turning.maxSpeed = maxSpeed;
        turning.avgSpeed = speedCnt > 0 ? (tolSpeed/speedCnt) : 0;
        
        [turningArr addObject:turning];
    }
    
    GPSLogItem * lastItem = (GPSLogItem*)[gpsLogs lastObject];
    GPSTurningItem * last = [[GPSTurningItem alloc] initWithInstSpeed:[lastItem.speed doubleValue]];
    last.eStat = eTurningEnd;
    [turningArr addObject:last];
    
    return turningArr;
}

@end