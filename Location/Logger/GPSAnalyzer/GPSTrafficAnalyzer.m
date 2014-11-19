//
//  GPSTrafficAnalyzer.m
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSTrafficAnalyzer.h"

@implementation GPSTrafficAnalyzer

+ (NSArray*) trafficJamsInTrip:(TripSummary*)sum withThreshold:(NSTimeInterval)threshold
{
    NSMutableArray * filterArr = [NSMutableArray arrayWithCapacity:4];
    NSArray * rawArr = [sum.traffic_jams allObjects];
    for (TrafficJam * jamPair in rawArr) {
        if (jamPair.end_date && jamPair.start_date && [jamPair.end_date timeIntervalSinceDate:jamPair.start_date] > threshold) {
            [filterArr addObject:jamPair];
        }
    }
    return filterArr;
}

@end
