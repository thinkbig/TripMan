//
//  CTRoute.m
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTRoute.h"
#import "ParkingRegion+Fetcher.h"

@implementation CTJam

+ (UIColor*) colorFromTraffic:(eStepTraffic)traffic
{
    if (eStepTrafficVerySlow == traffic) {
        return COLOR_STAT_RED;
    } else if (eStepTrafficSlow == traffic) {
        return COLOR_STAT_YELLOW;
    }
    return COLOR_STAT_GREEN;
}

- (eStepTraffic) trafficStat
{
    eStepTraffic curStat = eStepTrafficOk;
    CGFloat jamDuration = [self.duration floatValue];
    if (jamDuration > cHeavyTrafficJamThreshold) {
        CGFloat speed = [self avgSpeed];
        if (speed < cInsTrafficJamSpeed) {
            curStat = eStepTrafficVerySlow;
        } else {
            curStat = eStepTrafficSlow;
        }
    } else if (jamDuration > cTrafficJamThreshold) {
        curStat = eStepTrafficSlow;
    }
    
    return curStat;
}

- (NSNumber<Optional> *)duration {
    if (nil == _duration) {
        if (self.from && self.to) {
            _duration = @((int)[self.to.ts timeIntervalSinceDate:self.from.ts]);
        }
    }
    return _duration;
}

- (CGFloat) avgSpeed {
    CGFloat dist = [self.to distanceFrom:self.from];
    CGFloat duration = [self.duration floatValue];
    if (duration > 0) {
        return dist/duration;
    }
    return 0;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CTStep () {
    NSArray *     _pathArr;
}
@end

@implementation CTStep

- (NSNumber<Optional> *)duration {
    if (nil == _duration) {
        if (self.from && self.to) {
            _duration = @((int)[self.to.ts timeIntervalSinceDate:self.from.ts]);
        }
    }
    return _duration;
}

- (NSNumber<Optional> *)distance {
    if (nil == _distance) {
        if (self.from && self.to) {
            _distance = @((int)[self.to distanceFrom:self.from]);
        }
    }
    return _distance;
}

- (eStepTraffic) trafficStat {
    if (self.status) {
        NSInteger stat = [self.status integerValue];
        if (stat >= 0 && stat <= eStepTrafficDefMax) {
            return (eStepTraffic)stat;
        }
    } else {
        NSInteger maxTraffic = eStepTrafficOk;
        for (CTJam * jam in self.jams) {
            eStepTraffic curStat = [jam trafficStat];
            if (curStat > maxTraffic) {
                maxTraffic = curStat;
            }
        }
        self.status = @(maxTraffic);
        return (eStepTraffic)maxTraffic;
    }
    return eStepTrafficOk;
}

- (NSArray*) jamsWithThreshold:(CGFloat)threshold
{
    NSMutableArray * filteredJams = [NSMutableArray arrayWithCapacity:self.jams.count];
    for (CTJam * jam in self.jams) {
        if ([[jam duration] floatValue] > threshold) {
            [filteredJams addObject:jam];
        }
    }
    return filteredJams;
}

- (NSArray*) fullPathOfJam:(CTJam*)jam
{
    NSArray * pathArr = [self pathArray];
    NSMutableArray * pathFullArr = [NSMutableArray arrayWithObject:self.from];
    if (pathArr.count > 0) {
        [pathFullArr addObjectsFromArray:pathArr];
    }
    [pathFullArr addObject:self.to];
    
    NSMutableArray * jamArr = [NSMutableArray array];
    for (CTBaseLocation * loc in pathFullArr) {
        if (jamArr.count == 0) {
            // check jam from
            CGFloat jamFromDist = [jam.from distanceFrom:loc];
            if (jamFromDist < 50) {
                [jamArr addObject:jam.from];
            }
        } else {
            // check jam to
            CGFloat jamToDist = [jam.to distanceFrom:loc];
            if (jamToDist < 50) {
                [jamArr addObject:jam.to];
                break;
            } else {
                [jamArr addObject:loc];
            }
        }
    }
    
    return [jamArr copy];
}

- (void)setPath:(NSString<Optional> *)path
{
    _path = path;
    _pathArr = nil;
}

- (NSArray*) pathArray
{
    if (_pathArr) {
        return _pathArr;
    }
    if (self.path) {
        NSArray * segments = [self.path componentsSeparatedByString:@";"];
        NSMutableArray * ptArr = [NSMutableArray arrayWithCapacity:segments.count];
        for (NSString * oneSeg in segments) {
            CTBaseLocation * ctLoc = [CTBaseLocation new];
            if ([ctLoc updateWithCoordinateStr:oneSeg]) {
                [ptArr addObject:ctLoc];
            }
        }
        _pathArr = [ptArr copy];
    }
    return _pathArr;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CTRoute

- (NSNumber<Optional> *)duration {
    if (nil == _duration) {
        if (self.orig && self.dest) {
            _duration = @((int)[self.dest.ts timeIntervalSinceDate:self.orig.ts]);
        }
    }
    return _duration;
}

- (NSNumber<Optional> *)distance {
    if (nil == _distance) {
        if (self.orig && self.dest) {
            _distance = @((int)[self.dest distanceFrom:self.orig]);
        }
    }
    return _distance;
}

- (CTBaseLocation<Optional> *)orig
{
    if (nil == _orig) {
        _orig = [CTBaseLocation new];
    }
    return _orig;
}

- (CTBaseLocation<Optional> *)dest
{
    if (nil == _dest) {
        _dest = [CTBaseLocation new];
    }
    return _dest;
}

- (void) updateWithDestRegion:(ParkingRegion*)region fromCurrentLocation:(CLLocation*)curLoc
{
    self.orig = [CTBaseLocation new];
    self.dest = [CTBaseLocation new];
    
    self.orig.name = @"当前位置";
    [self.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    
    self.dest.name = [region nameWithDefault:@"目的地"];
    [self.dest updateWithCoordinate:[GeoTransformer earth2Baidu:[region centerCoordinate]]];
}

- (void) mergeFromAnother:(CTRoute*)route
{
    self.distance = route.distance;
    self.duration = route.duration;
    self.steps = route.steps;
    self.coor_type = route.coor_type;
    if (route.orig) {
        if (route.orig.name) {
            self.orig.name = route.orig.name;
        }
        if (route.orig.lat && route.orig.lon) {
            self.orig.lat = route.orig.lat;
            self.orig.lon = route.orig.lon;
        }
    }
    if (route.dest) {
        if (route.dest.name) {
            self.dest.name = route.dest.name;
        }
        if (route.dest.lat && route.dest.lon) {
            self.dest.lat = route.dest.lat;
            self.dest.lon = route.dest.lon;
        }
    }
}

- (eStepTraffic) trafficStat
{
    if (self.most_jam) {
        return [self.most_jam trafficStat];
    }
    NSInteger maxTraffic = eStepTrafficOk;
    for (CTStep * step in self.steps) {
        eStepTraffic curStat = [step trafficStat];
        if (curStat > maxTraffic) {
            maxTraffic = curStat;
        }
    }
    return (eStepTraffic)maxTraffic;
}

- (void)setCoorType:(eCoorType)coorType
{
    if (eCoorTypeBaidu == coorType) {
        self.coor_type = @"baidu";
    } else if (eCoorTypeMars == coorType) {
        self.coor_type = @"mars";
    } else {
        self.coor_type = @"gps";
    }
}

- (eCoorType) coorType
{
    if ([self.coor_type isEqualToString:@"baidu"]) {
        return eCoorTypeBaidu;
    } else if ([self.coor_type isEqualToString:@"mars"]) {
        return eCoorTypeMars;
    }
    return eCoorTypeGps;
}

@end
