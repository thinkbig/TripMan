//
//  TripSummary.m
//  TripMan
//
//  Created by taq on 11/16/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripSummary.h"
#import "DrivingInfo.h"
#import "EnvInfo.h"
#import "RegionGroup.h"
#import "TrafficJam.h"
#import "TurningInfo.h"
#import "WeatherInfo.h"


@implementation TripSummary

@dynamic avg_speed;
@dynamic end_date;
@dynamic is_analyzed;
@dynamic max_speed;
@dynamic start_date;
@dynamic total_dist;
@dynamic total_during;
@dynamic traffic_avg_speed;
@dynamic traffic_jam_cnt;
@dynamic traffic_jam_dist;
@dynamic traffic_jam_during;
@dynamic traffic_light_tol_cnt;
@dynamic traffic_light_jam_cnt;
@dynamic driving_info;
@dynamic environment;
@dynamic region_group;
@dynamic traffic_jams;
@dynamic turning_info;
@dynamic weather;

@end
