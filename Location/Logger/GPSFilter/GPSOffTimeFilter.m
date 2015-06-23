//
//  GPSOffTimeFilter.m
//  Location
//
//  Created by taq on 9/29/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSOffTimeFilter.h"
#import "GPSLogItem.h"
#import "TripSimulator.h"

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

+ (NSArray*) filterWithTurning:(NSArray*)rawRoute
{
    NSMutableArray * route = [NSMutableArray array];
    NSUInteger tolCnt = rawRoute.count;
    if (tolCnt <= 3) {
        return rawRoute;
    } else {
        [route addObject:rawRoute[0]];
        for (int i = 1; i < tolCnt-1; i++) {
            GPSLogItem * objLast = [route lastObject];
            GPSLogItem * obj = rawRoute[i];
            GPSLogItem * objNext = rawRoute[i+1];
            
            CGFloat dist2Last = [obj distanceFrom:objLast];
            if (dist2Last < cRouteStepMerge) {
                [route addObject:objNext];
                i++;
                continue;
            }
            
            CGPoint pt1 = [GPSOffTimeFilter item2Point:objLast];
            CGPoint pt2 = [GPSOffTimeFilter item2Point:obj];
            CGPoint pt3 = [GPSOffTimeFilter item2Point:objNext];
            CGFloat angle = [GPSOffTimeFilter checkPointAngle:pt1 antPt:pt2 antPt:pt3];
            
            BOOL shouldAddItem = NO;
            if (angle > 12 || dist2Last > cRouteStepMax) {
                shouldAddItem = YES;
            }
            
            if (shouldAddItem) {
                [route addObject:obj];
                obj.stepAngle = angle;
            } else {
                [route addObject:objNext];
                i++;
            }
        }
        [route addObject:[rawRoute lastObject]];
    }
    return route;
}

//+ (GPSLogItem*) angleForSteps:(NSArray*)steps
//{
//    if (steps.count <= 2) {
//        return nil;
//    }
//    CGFloat maxDist = 0;
//    GPSLogItem * maxItem = nil;
//    GPSLogItem * first = steps[0];
//    GPSLogItem * last = [steps lastObject];
//    CGFloat dist = [last distanceFrom:first];
//    if (dist == 0) {
//        return nil;
//    }
//    for (int i = 1; i < steps.count-1; i++) {
//        GPSLogItem * cur = steps[i];
//        CGFloat curDist = [cur distanceFrom:first] + [cur distanceFrom:last];
//        if (maxDist < curDist) {
//            maxDist = curDist;
//            maxItem = cur;
//        }
//    }
//    
//    
//    if (maxDist/dist > 2.0/1.73205) {
//        return maxItem;
//    }
//    return nil;
//}

+ (NSArray*) keyRouteFromGPS:(NSArray*)gpsData autoFilter:(BOOL)filter
{
    CGFloat gpsErrSmall = 30;
    CGFloat gpsErrBig = 100;
    CGFloat thresShort = 50;
    CGFloat thresShortMax = 800;
    
    if (gpsData.count <= 2) {
        return gpsData;
    }
    
    GPSLogItem * first = gpsData[0];
    GPSLogItem * end = [gpsData lastObject];
    
    // 第一次筛选，使用thresShort
    NSMutableArray * rawRoute1 = [NSMutableArray array];
    NSMutableArray * tmpAngleArr = [NSMutableArray array];
    NSUInteger tolCnt1 = gpsData.count;
    [gpsData enumerateObjectsUsingBlock:^(GPSLogItem * obj, NSUInteger idx, BOOL *stop) {
        if (idx == 0 || obj.isKeyPoint) {
            [rawRoute1 addObject:obj];
            [tmpAngleArr addObject:obj];
        } else if (idx == tolCnt1-1) {
            GPSLogItem * lastGps = [rawRoute1 lastObject];
            CGFloat dist = [lastGps distanceFrom:obj];
            if (dist < thresShort) {
                [rawRoute1 removeLastObject];
            }
            [rawRoute1 addObject:obj];
        } else {
            GPSLogItem * lastTmp = [tmpAngleArr lastObject];
            if ([obj distanceFrom:lastTmp] > 10) {
                [tmpAngleArr addObject:obj];
            }
            
            GPSLogItem * lastGps = [rawRoute1 lastObject];
            CGFloat distToLast = [lastGps distanceFrom:obj];
            
            CGFloat distToSt = [first distanceFrom:obj];
            CGFloat distToEnd = [end distanceFrom:obj];
            CGFloat gpsErr = gpsErrSmall;
            if (distToSt < 500 || distToEnd < 300) {
                gpsErr = gpsErrBig;
            }
            if ((distToLast > thresShortMax && [obj.horizontalAccuracy doubleValue] < gpsErrBig*2) || (distToLast > thresShort && [obj.horizontalAccuracy doubleValue] < gpsErr)) {
//                GPSLogItem * turnItem = [self angleForSteps:tmpAngleArr];
//                if (turnItem) {
//                    [rawRoute1 addObject:turnItem];
//                }
                [rawRoute1 addObject:obj];
                [tmpAngleArr removeAllObjects];
            }
        }
    }];
        
    // 第二次筛选，对于非起点终点，非拐点的位置，增加他的间隔
    NSArray * rawRoute = rawRoute1;
    if (filter) {
        NSArray * lastRoute = nil;
        do {
            lastRoute = rawRoute;
            rawRoute = [GPSOffTimeFilter filterWithTurning:rawRoute];
        } while (rawRoute.count != lastRoute.count);
    }
    
    return rawRoute;
}

+ (NSString*) routeToString:(NSArray*)route withTimeStamp:(BOOL)withTime
{
    if (route.count > 0) {
        NSString * seg = @"";
        NSMutableString * wayStr = [[NSMutableString alloc] init];
        for (GPSLogItem * item in route) {
            if (withTime) {
                [wayStr appendFormat:@"%@%.f,%.5f,%.5f", seg, [item.timestamp timeIntervalSince1970], [item.latitude doubleValue], [item.longitude doubleValue]];
            } else {
                [wayStr appendFormat:@"%@%.5f,%.5f", seg, [item.latitude doubleValue], [item.longitude doubleValue]];
            }
            
            seg = @"|";
        }
        return wayStr;
    }
    return nil;
}

+ (NSArray*) stringToLocationRoute:(NSString*)routeStr
{
    NSArray * segments = [routeStr componentsSeparatedByString:@"|"];
    NSMutableArray * ptArr = [NSMutableArray arrayWithCapacity:segments.count];
    for (NSString * oneSeg in segments) {
        NSArray * coorNum = [oneSeg componentsSeparatedByString:@","];
        if (coorNum.count == 3) {
            CTBaseLocation * loc = [[CTBaseLocation alloc] init];
            loc.ts = [NSDate dateWithTimeIntervalSince1970:[coorNum[0] floatValue]];
            loc.lat = @([coorNum[1] floatValue]);
            loc.lon = @([coorNum[2] floatValue]);
            [ptArr addObject:loc];
        }
    }
    return ptArr;
}

+ (void) smoothGpsSpeed:(NSArray*)gpsData
{
    TripSimulator * simulator = [TripSimulator new];
    simulator.gpsLogs = gpsData;
    
}

+ (NSArray*) smoothGPSData:(NSArray*)gpsData iteratorCnt:(NSInteger)repeat
{
    if (repeat <= 0) {
        return gpsData;
    }
    NSMutableArray * smoothData = [NSMutableArray arrayWithCapacity:gpsData.count];
    NSMutableArray * penddingData = [NSMutableArray arrayWithCapacity:8];
    
    GPSLogItem * lastItem = nil;
    for (GPSLogItem * item in gpsData)
    {
        if (lastItem && [lastItem isEqual:item]) {
            continue;       //  忽略重复点
        }
        lastItem = item;
        
        CGFloat accuracy = [item.horizontalAccuracy doubleValue];
        // 如果该gpslog的gps精度无效（<0）或者大于100米，则丢弃
        if (accuracy < 0 || accuracy > 200) {
            continue;
        }
        if (accuracy < 90) {
            // regard as good location, 精度小于30米，则直接使用不做去噪处理
            if (penddingData.count == 1) {
                if (smoothData.count > 0) {
                    GPSLogItem * newItem = [self smoothItem:@[[smoothData lastObject], item]];
                    [smoothData addObject:newItem];
                }
            } else if (penddingData.count > 1) {
                // 处理去噪队列，不同的精度给不同的权重，去一个平均值
                GPSLogItem * newItem = [self smoothItem:penddingData];
                [smoothData addObject:newItem];
            }
            [penddingData removeAllObjects];
            [smoothData addObject:item];
            continue;
        } else {
            // 否则，加入队列去噪
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

+ (CGFloat)checkPointAngle:(CGPoint)pt1 antPt:(CGPoint)pt2 antPt:(CGPoint)pt3
{
    return [GPSOffTimeFilter checkPointAngle:pt1 antPt:pt2 antPt:pt2 andPt:pt3];
}

+ (CGFloat)checkPointAngle:(CGPoint)pt1 antPt:(CGPoint)pt2 antPt:(CGPoint)pt3 andPt:(CGPoint)pt4;
{
    CGFloat angle1 = [GPSOffTimeFilter angleFromPoint:pt1 toPoint:pt2];
    CGFloat angle2 = [GPSOffTimeFilter angleFromPoint:pt3 toPoint:pt4];
    
    CGFloat angleD = fabs(angle2 - angle1);
    angleD = angleD > 180 ? 360-angleD : angleD;
    
    return angleD;
}

+ (CGPoint)coor2Point:(CLLocationCoordinate2D)coor
{
    return CGPointMake(coor.latitude*1000000, coor.longitude*1000000);
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
    
    // 寻找距离 firstIdx 到 secondIdx 线段最远的一个点，作为下一个拐点的候选点
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
    
    // 判断这个候选拐点是否是真的拐点，通过距离，角度，等来判断
    if (maxItem) {
        CGFloat dist1 = [firstItem distanceFrom:maxItem];
        CGFloat dist2 = [maxItem distanceFrom:secondItem];
        if (dist1 < 100 && dist2 < 100) {
            // if all distance is less than 100m, remove the angle point
            featureIdx = -1;
        } else if ((dist1 < 200 && dist2 < 200) && [GPSOffTimeFilter checkPointAngle:firstPt antPt:maxPt antPt:secondPt] < 60) {
            // if all distance is less than 200m, check the angle
            featureIdx = -1;
        } else if (dist1 < 20 || dist2 < 20) {
            // if one distence is less than 20m, remove this line
            featureIdx = -1;
        } else if ((dist1*5 < dist2 || dist2*5 < dist1) && (dist1 < 60 || dist2 < 60)) {
            // the distance is within 5 times, and the shortest is less than 60m
            featureIdx = -1;
        } else if ([GPSOffTimeFilter checkPointAngle:firstPt antPt:maxPt antPt:secondPt] < 10) {
            // all else if the angle is less than 10 degree
            featureIdx = -1;
        }
    }
    
    if (featureIdx > 0) {
        return featureIdx;
    }
    
    // 返回-1，表示找不到满足条件的拐点
    return -1;
}

- (void)_calFeaturePointsAtIdx:(NSInteger)idx
{
    if (idx+1 < self.anglePointIdx.count)
    {
        NSInteger firstIdx = [self.anglePointIdx[idx] integerValue];
        NSInteger secondIdx = [self.anglePointIdx[idx+1] integerValue];
        
        // 寻找相邻2个拐点之间，可能还存在的拐点（最初的2个点即为起点和终点）
        NSInteger featureIdx = [self featurePointWithIdx:firstIdx andPt:secondIdx];
        
        // 如果找到了可能的拐点，则把拐点插入队列，递归查找下一个
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
        
        CGPoint pt1 = [GPSOffTimeFilter item2Point:self.smoothData[idx1]];
        CGPoint pt2 = [GPSOffTimeFilter item2Point:self.smoothData[idx2]];
        CGPoint pt3 = [GPSOffTimeFilter item2Point:self.smoothData[idx3]];
        
        NSInteger delIdx = -1;
        NSInteger nextIdx = idx+1;
        // 二次筛选拐点，如果相邻拐点的角度小于15度，则认为不是拐点，删除改拐点，递归查找下一个
        CGFloat filterThres = 30;
        if (idx < 2) {
            // 起点位置因为精度比较低，并且有一段缺失，因此减少判断阈值
            filterThres = 15;
        }
        if ([GPSOffTimeFilter checkPointAngle:pt1 antPt:pt2 antPt:pt3] < filterThres) {
            delIdx = idx+1;
            nextIdx = idx;
        }
        
        if (delIdx > 0) {
            [self.anglePointIdx removeObjectAtIndex:delIdx];
        }
        [self _filterFeaturePointsAtIdx:nextIdx];
    }
}

- (void)_filterFeaturePoints2AtIdx:(NSInteger)idx
{
    if (idx+2 < self.anglePointIdx.count)
    {
        NSInteger idx1 = [self.anglePointIdx[idx] integerValue];
        NSInteger idx2 = [self.anglePointIdx[idx+1] integerValue];
        NSInteger idx3 = [self.anglePointIdx[idx+2] integerValue];
        
        CGPoint pt1 = [GPSOffTimeFilter item2Point:self.smoothData[idx1]];
        CGPoint pt2 = [GPSOffTimeFilter item2Point:self.smoothData[idx2]];
        CGPoint pt3 = [GPSOffTimeFilter item2Point:self.smoothData[idx3]];
        
        NSInteger delIdx = -1;
        NSInteger nextIdx = idx+1;

        // 一个拐点有可能会被识别出多个拐点，因为采样精度的原因，合并距离相近的拐点
        if (delIdx < 0 && idx+3 < self.anglePointIdx.count) {
            CGFloat dist = [(GPSLogItem*)self.smoothData[idx2] distanceFrom:self.smoothData[idx3]];
            if (dist < 260) {
                NSInteger idx4 = [self.anglePointIdx[idx+3] integerValue];
                CGPoint pt4 = [GPSOffTimeFilter item2Point:self.smoothData[idx4]];
                CGFloat angle123 = [GPSOffTimeFilter checkPointAngle:pt1 antPt:pt2 antPt:pt3];
                CGFloat angle234 = [GPSOffTimeFilter checkPointAngle:pt2 antPt:pt3 antPt:pt4];
                CGFloat angle1234 = [GPSOffTimeFilter checkPointAngle:pt1 antPt:pt2 antPt:pt3 andPt:pt4];
                if (angle1234 > 70 && angle1234 < 110) {
                    if (angle123 > angle234) {
                        delIdx = idx+2;
                    } else {
                        delIdx = idx+1;
                    }
                }
            }
        }
        
        if (delIdx > 0) {
            [self.anglePointIdx removeObjectAtIndex:delIdx];
        }
        [self _filterFeaturePoints2AtIdx:nextIdx];
    }
}

- (void) calGPSDataForTurning:(NSArray*)gpsData smoothFirst:(BOOL)smooth
{
    // 先去噪，平滑数据
    self.smoothData = gpsData;
    if (smooth) {
        self.smoothData = [GPSOffTimeFilter smoothGPSData:gpsData iteratorCnt:3];
    }
    self.anglePointIdx = [NSMutableArray array];
    if (self.smoothData.count > 0)
    {
        // 加入初始拐点（起点和终点）
        [self.anglePointIdx addObject:@0];
        if (self.smoothData.count > 1) {
            [self.anglePointIdx addObject:@(self.smoothData.count-1)];
        }
        
        // 递归寻找拐点
        [self _calFeaturePointsAtIdx:0];
        
        // 验证筛选拐点
        [self _filterFeaturePointsAtIdx:0];
        [self _filterFeaturePoints2AtIdx:0];
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
    first.distAfterTurning = [firstItem distanceFrom:secondItem];
    [turningArr addObject:first];
    
    for (NSInteger i = 1; i < gpsLogs.count-1; i++)
    {
        GPSLogItem * prevItem = (GPSLogItem*)gpsLogs[i-1];
        GPSLogItem * item = (GPSLogItem*)gpsLogs[i];
        GPSLogItem * nextItem = (GPSLogItem*)gpsLogs[i+1];
        
        GPSTurningItem * turning = [[GPSTurningItem alloc] initWithInstSpeed:[item.speed doubleValue]];
        turning.duringAfterTurning = [nextItem.timestamp timeIntervalSinceDate:item.timestamp];
        turning.distAfterTurning = [item distanceFrom:nextItem];
        turning.angle = [GPSOffTimeFilter checkPointAngle:[GPSOffTimeFilter item2Point:prevItem] antPt:[GPSOffTimeFilter item2Point:item] antPt:[GPSOffTimeFilter item2Point:nextItem]];
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
            CGFloat dist = [item distanceFrom:lastItem];
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
            CGFloat dist = [item distanceFrom:lastItem];
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
