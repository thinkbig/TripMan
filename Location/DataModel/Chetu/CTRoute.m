//
//  CTRoute.m
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTRoute.h"
#import "ParkingRegion+Fetcher.h"
#import "GeoTransformer.h"

@implementation CTJam

- (eStepTraffic) trafficStat
{
    CGFloat jamDuration = [self.duration floatValue];
    if (jamDuration > cHeavyTrafficJamThreshold) {
        return eStepTrafficVerySlow;
    } else if (jamDuration > cHeavyTrafficJamThreshold/2.0) {
        return eStepTrafficSlow;
    }
    return eStepTrafficOk;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CTStep

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
        return (eStepTraffic)maxTraffic;
    }
    return eStepTrafficOk;
}

- (NSArray*) pathArray
{
    if (self.path) {
        NSArray * segments = [self.path componentsSeparatedByString:@";"];
        NSMutableArray * ptArr = [NSMutableArray arrayWithCapacity:segments.count];
        for (NSString * oneSeg in segments) {
            CTBaseLocation * ctLoc = [CTBaseLocation new];
            if ([ctLoc updateWithCoordinateStr:oneSeg]) {
                [ptArr addObject:ctLoc];
            }
        }
        return ptArr;
    }
    return nil;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CTRoute

- (void) updateWithDestRegion:(ParkingRegion*)region fromCurrentLocation:(CLLocation*)curLoc
{
    self.orig = [CTBaseLocation new];
    self.dest = [CTBaseLocation new];
    
    self.orig.name = @"当前位置";
    [self.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    
    self.dest.name = [region nameWithDefault:@"目的地"];
    [self.dest updateWithCoordinate:[GeoTransformer earth2Baidu:[region centerCoordinate]]];
}

- (void) updateWithDestCoor:(CLLocationCoordinate2D)coor andDestName:(NSString*)destName fromCurrentLocation:(CLLocation*)curLoc
{
    self.orig = [CTBaseLocation new];
    self.dest = [CTBaseLocation new];
    
    self.orig.name = @"当前位置";
    [self.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    
    self.dest.name = destName ? destName : @"目的地";
    [self.dest updateWithCoordinate:[GeoTransformer earth2Baidu:coor]];
}

- (void) mergeFromAnother:(CTRoute*)route
{
    self.distance = route.distance;
    self.duration = route.duration;
    self.steps = route.steps;
    if (route.orig) {
        if (route.orig.name) {
            self.orig.name = route.orig.name;
        }
        self.orig.lat = route.orig.lat;
        self.orig.lon = route.orig.lon;
    }
    if (route.dest) {
        if (route.dest.name) {
            self.dest.name = route.dest.name;
        }
        self.dest.lat = route.dest.lat;
        self.dest.lon = route.dest.lon;
    }
}

- (eStepTraffic) trafficStat {
    NSInteger maxTraffic = eStepTrafficOk;
    for (CTStep * step in self.steps) {
        eStepTraffic curStat = [step trafficStat];
        if (curStat > maxTraffic) {
            maxTraffic = curStat;
        }
    }
    return (eStepTraffic)maxTraffic;
}

@end
