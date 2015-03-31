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

@implementation CTStep

- (eStepTraffic) trafficStat {
    NSInteger stat = [self.status integerValue];
    if (stat >= 0 && stat <= eStepTrafficDefMax) {
        return (eStepTraffic)stat;
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
    self.status = route.status;
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
    NSInteger stat = [self.status integerValue];
    if (stat >= 0 && stat <= eStepTrafficDefMax) {
        return (eStepTraffic)stat;
    }
    return eStepTrafficOk;
}

@end
