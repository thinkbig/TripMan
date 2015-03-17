//
//  TripSummary+Fetcher.m
//  TripMan
//
//  Created by taq on 2/4/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripSummary+Fetcher.h"
#import "TurningInfo+Fetcher.h"
#import "DrivingInfo+Fetcher.h"
#import "EnvInfo+Fetcher.h"
#import "TrafficJam+Fetcher.h"

@implementation TripSummary (Fetcher)

- (eTrafficStatus) trafficStatus
{
    eTrafficStatus status = eTrafficGreen;
    NSInteger heavyJam = [self.traffic_heavy_jam_cnt integerValue];
    if (heavyJam > 0) {
        NSArray * allJams = [self.traffic_jams allObjects];
        CGFloat maxDuring = 0;
        TrafficJam * maxJam = nil;
        for (TrafficJam * jam in allJams) {
            if (maxDuring < [jam.traffic_jam_during floatValue]) {
                maxDuring = [jam.traffic_jam_during floatValue];
                maxJam = jam;
            }
        }
        if (maxDuring > 60*5) {
            status = eTrafficYellow;
            if (maxDuring > 60*10 || [maxJam.traffic_jam_dist floatValue] < 300) {
                status = eTrafficRed;
            }
        }
    }
    return status;
}

- (BOOL) readyForUpload
{
    NSString * st_parkingId = self.region_group.start_region.parking_id;
    NSString * ed_parkingId = self.region_group.end_region.parking_id;
    
    return [self.is_analyzed boolValue] && st_parkingId.length > 0 && ed_parkingId.length > 0;
}


- (NSDictionary*) toJsonDict
{
    if (![self readyForUpload]) {
        return nil;
    }
    NSMutableDictionary * mutableDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @((unsigned long long)[self.start_date timeIntervalSince1970]), @"start_date",
                                         @((unsigned long long)[self.end_date timeIntervalSince1970]), @"end_date",
                                         self.region_group.start_region.parking_id, @"st_parkingId",
                                         self.region_group.end_region.parking_id, @"ed_parkingId", nil];
    
    mutableDict[@"total_dist"] = self.total_dist;
    mutableDict[@"total_during"] = self.total_during;
    mutableDict[@"max_speed"] = self.max_speed;
    mutableDict[@"avg_speed"] = self.avg_speed;
    mutableDict[@"traffic_jam_dist"] = self.traffic_jam_dist;
    mutableDict[@"traffic_jam_during"] = self.traffic_jam_during;
    mutableDict[@"traffic_avg_speed"] = self.traffic_avg_speed;
    mutableDict[@"traffic_light_tol_cnt"] = self.traffic_light_tol_cnt;
    mutableDict[@"traffic_light_jam_cnt"] = self.traffic_light_jam_cnt;
    mutableDict[@"traffic_light_waiting"] = self.traffic_light_waiting;
    mutableDict[@"traffic_heavy_jam_cnt"] = self.traffic_heavy_jam_cnt;
    mutableDict[@"traffic_jam_max_during"] = self.traffic_jam_max_during;
    
    NSDictionary * turning_info = [self.turning_info toJsonDict];
    if (turning_info) {
        mutableDict[@"turning_info"] = turning_info;
    }
    NSDictionary * driving_info = [self.driving_info toJsonDict];
    if (driving_info) {
        mutableDict[@"driving_info"] = driving_info;
    }
    NSDictionary * environment = [self.environment toJsonDict];
    if (environment) {
        mutableDict[@"environment"] = environment;
    }
    
    NSMutableArray * jams = [NSMutableArray arrayWithCapacity:self.traffic_jams.count];
    for (TrafficJam * jam in self.traffic_jams) {
        [jams addObject:[jam toJsonDict]];
    }
    mutableDict[@"traffic_jams"] = jams;

    return mutableDict;
}

@end
