//
//  DataDebugPrinter.m
//  Location
//
//  Created by taq on 11/7/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "DataDebugPrinter.h"

@implementation DataDebugPrinter

+ (NSString *)printTripSummary:(TripSummary *)sum
{
    static NSDateFormatter *sDateFormatter = nil;
    if (nil == sDateFormatter) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        [sDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    
    return [NSString stringWithFormat:@"from: %@-%@-%@, to:%@-%@-%@, dist=%@, during=%@, max_speed=%@, jam_during=%@", (sum.start_date?[sDateFormatter stringFromDate:sum.start_date]:nil), sum.region_group.start_region.street, sum.region_group.start_region.nearby_poi, (sum.end_date?[sDateFormatter stringFromDate:sum.end_date]:nil), sum.region_group.end_region.street, sum.region_group.end_region.nearby_poi, sum.total_dist, sum.total_during, sum.max_speed, sum.traffic_jam_during];
}

+ (NSString*) printDrivingInfo:(DrivingInfo*)info
{
    CGFloat maxAcceDiff = [info.max_acce_end_speed floatValue] - [info.max_acce_begin_speed floatValue];
    CGFloat maxBreakDiff = [info.max_breaking_end_speed floatValue] - [info.max_breaking_begin_speed floatValue];
    return [NSString stringWithFormat:@"acce:(%@, hard=%@, maxAcce=%@), break:(%@, hard=%@, maxBreak=%@), short:(%@, %@, %@)", info.acce_cnt, info.hard_acce_cnt, @(maxAcceDiff), info.breaking_cnt, info.hard_breaking_cnt, @(maxBreakDiff), info.shortest_40, info.shortest_60, info.shortest_80];
}

+ (NSString*) printEnvInfo:(EnvInfo*)info
{
    return [NSString stringWithFormat:@"day:(dist=%@, speed=%@/%@, during=%@), night:(dist=%@, speed=%@/%@, during=%@)", info.day_dist, info.day_avg_speed, info.day_max_speed, info.day_during, info.night_dist, info.night_avg_speed, info.night_max_speed, info.night_during];
}

+ (NSString*) printTurningInfo:(TurningInfo*)info
{
    return [NSString stringWithFormat:@"left:(cnd=%@, %@/%@), right:(cnd=%@, %@/%@), turn:(cnd=%@, %@/%@)", info.left_turn_cnt, info.left_turn_avg_speed, info.left_turn_max_speed, info.right_turn_cnt, info.right_turn_avg_speed, info.right_turn_max_speed, info.turn_round_cnt, info.turn_round_avg_speed, info.turn_round_max_speed];
}

@end
