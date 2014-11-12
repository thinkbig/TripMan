//
//  GPSAnalyzeItem.m
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSAnalyzeSumItem.h"

@implementation GPSAnalyzeSumItem

- (id)initWithDBResultSet:(FMResultSet*)resultSet
{
    if ((self = [super init]))
	{
        self.db_id = [resultSet longForColumn:@"id"];
        
		self.start_date = [resultSet dateForColumn:@"start_date"];
        self.end_date = [resultSet dateForColumn:@"end_date"];
        self.total_dist = [resultSet objectForColumnName:@"total_dist"];
        self.total_during = [resultSet objectForColumnName:@"total_during"];
        self.avg_speed = [resultSet objectForColumnName:@"avg_speed"];
        self.max_speed = [resultSet objectForColumnName:@"max_speed"];
        self.traffic_jam_dist = [resultSet objectForColumnName:@"traffic_jam_dist"];
        self.traffic_jam_during = [resultSet objectForColumnName:@"traffic_jam_during"];
        self.desc = [resultSet stringForColumn:@"desc"];

		self.is_analyzed = [resultSet objectForColumnName:@"is_analyzed"];
	}
	return self;
}

- (NSString *)description
{
    static NSDateFormatter *sDateFormatter = nil;
    if (nil == sDateFormatter) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        [sDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }

    return [NSString stringWithFormat:@"id=%ld, start_date=%@, end_date=%@, total_dist=%@, total_during=%@, avg_speed=%@, max_speed=%@, traffic_jam_dist=%@, traffic_jam_during=%@", _db_id, (_start_date?[sDateFormatter stringFromDate:_start_date]:nil), (_end_date?[sDateFormatter stringFromDate:_end_date]:nil), _total_dist, _total_during, _avg_speed, _max_speed, _traffic_jam_dist, _traffic_jam_during];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation AnalyzeEnvItem

- (id)initWithTripId:(long)tripId
{
    if ((self = [super init])) {
        self.db_id = tripId;
    }
    return self;
}

- (id)initWithDBResultSet:(FMResultSet*)resultSet
{
    if ((self = [super init]))
    {
        self.db_id = [resultSet longForColumn:@"trip_id"];
        
        self.day_dist = [resultSet objectForColumnName:@"day_dist"];
        self.day_during = [resultSet objectForColumnName:@"day_during"];
        self.day_avg_speed = [resultSet objectForColumnName:@"day_avg_speed"];
        self.day_max_speed = [resultSet objectForColumnName:@"day_max_speed"];
        
        self.night_dist = [resultSet objectForColumnName:@"night_dist"];
        self.night_during = [resultSet objectForColumnName:@"night_during"];
        self.night_avg_speed = [resultSet objectForColumnName:@"night_avg_speed"];
        self.night_max_speed = [resultSet objectForColumnName:@"night_max_speed"];
        
        self.weather = [resultSet objectForColumnName:@"weather"];
        self.temperature = [resultSet objectForColumnName:@"temperature"];
        self.moisture = [resultSet objectForColumnName:@"moisture"];
        self.wind = [resultSet objectForColumnName:@"wind"];
        
        self.is_analyzed = [resultSet objectForColumnName:@"is_analyzed"];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"id=%ld, day_dist=%@, day_during=%@, day_avg_speed=%@, day_max_speed=%@, night_dist=%@, night_during=%@, night_avg_speed=%@, night_max_speed=%@", _db_id, _day_dist, _day_during, _day_avg_speed, _day_max_speed, _night_dist, _night_during, _night_avg_speed, _night_max_speed];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation AnalyzeDrivingItem

- (id)initWithTripId:(long)tripId
{
    if ((self = [super init])) {
        self.db_id = tripId;
    }
    return self;
}

- (id)initWithDBResultSet:(FMResultSet*)resultSet
{
    if ((self = [super init]))
    {
        self.db_id = [resultSet longForColumn:@"trip_id"];
        
        self.breaking_cnt = [resultSet objectForColumnName:@"breaking_cnt"];
        self.hard_breaking_cnt = [resultSet objectForColumnName:@"hard_breaking_cnt"];
        self.max_breaking_begin_speed = [resultSet objectForColumnName:@"max_breaking_begin_speed"];
        self.max_breaking_end_speed = [resultSet objectForColumnName:@"max_breaking_end_speed"];
        
        self.acce_cnt = [resultSet objectForColumnName:@"acce_cnt"];
        self.hard_acce_cnt = [resultSet objectForColumnName:@"hard_acce_cnt"];
        self.max_acce_begin_speed = [resultSet objectForColumnName:@"max_acce_begin_speed"];
        self.max_acce_end_speed = [resultSet objectForColumnName:@"max_acce_end_speed"];
        
        self.shortest_40 = [resultSet objectForColumnName:@"shortest_40"];
        self.shortest_60 = [resultSet objectForColumnName:@"shortest_60"];
        self.shortest_80 = [resultSet objectForColumnName:@"shortest_80"];
        
        self.is_analyzed = [resultSet objectForColumnName:@"is_analyzed"];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"id=%ld, breaking_cnt=%@, hard_breaking_cnt=%@, max_breaking_speed_within_5_seconds=%f, acce_cnt=%@, hard_acce_cnt=%@, max_accelate_speed_within_5_seconds=%f, shortest_40=%@, shortest_60=%@, shortest_80=%@", _db_id, _breaking_cnt, _hard_breaking_cnt, [_max_breaking_end_speed doubleValue]-[_max_breaking_begin_speed doubleValue], _acce_cnt, _hard_acce_cnt, [_max_acce_end_speed doubleValue]-[_max_acce_begin_speed doubleValue], _shortest_40, _shortest_60, _shortest_80];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation AnalyzeTurningItem

- (id)initWithTripId:(long)tripId
{
    if ((self = [super init])) {
        self.db_id = tripId;
    }
    return self;
}

- (id)initWithDBResultSet:(FMResultSet*)resultSet
{
    if ((self = [super init]))
    {
        self.db_id = [resultSet longForColumn:@"trip_id"];
        
        self.left_turn_cnt = [resultSet objectForColumnName:@"left_turn_cnt"];
        self.left_turn_avg_speed = [resultSet objectForColumnName:@"left_turn_avg_speed"];
        self.left_turn_max_speed = [resultSet objectForColumnName:@"left_turn_max_speed"];
        
        self.right_turn_cnt = [resultSet objectForColumnName:@"right_turn_cnt"];
        self.right_turn_avg_speed = [resultSet objectForColumnName:@"right_turn_avg_speed"];
        self.right_turn_max_speed = [resultSet objectForColumnName:@"right_turn_max_speed"];
        
        self.turn_round_cnt = [resultSet objectForColumnName:@"turn_round_cnt"];
        self.turn_round_avg_speed = [resultSet objectForColumnName:@"turn_round_avg_speed"];
        self.turn_round_max_speed = [resultSet objectForColumnName:@"turn_round_max_speed"];
        
        self.is_analyzed = [resultSet objectForColumnName:@"is_analyzed"];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"id=%ld, left_turn_cnt=%@, left_turn_avg_speed=%@, left_turn_max_speed=%@, right_turn_cnt=%@, right_turn_avg_speed=%@, right_turn_max_speed=%@, turn_round_cnt=%@, turn_round_avg_speed=%@. turn_round_max_speed=%@", _db_id, _left_turn_cnt, _left_turn_avg_speed, _left_turn_max_speed, _right_turn_cnt, _right_turn_avg_speed, _right_turn_max_speed, _turn_round_cnt, _turn_round_avg_speed, _turn_round_max_speed];
}

@end

