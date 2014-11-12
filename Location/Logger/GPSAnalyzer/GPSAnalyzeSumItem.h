//
//  GPSAnalyzeItem.h
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface GPSAnalyzeSumItem : NSObject

@property (nonatomic) long                          db_id;

@property (nonatomic, strong) NSDate   *            start_date;
@property (nonatomic, strong) NSDate   *            end_date;

@property (nonatomic, strong) NSNumber   *          total_dist;
@property (nonatomic, strong) NSNumber   *          total_during;
@property (nonatomic, strong) NSNumber   *          avg_speed;
@property (nonatomic, strong) NSNumber   *          max_speed;

@property (nonatomic, strong) NSNumber   *          traffic_jam_dist;
@property (nonatomic, strong) NSNumber   *          traffic_jam_during;
@property (nonatomic, strong) NSNumber   *          traffic_avg_speed;

@property (nonatomic, strong) NSString   *          desc;

@property (nonatomic, strong) NSNumber   *          is_analyzed;

- (id)initWithDBResultSet:(FMResultSet*)resultSet;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface AnalyzeEnvItem : NSObject

@property (nonatomic) long                          db_id;

// env param
@property (nonatomic, strong) NSNumber   *          day_dist;
@property (nonatomic, strong) NSNumber   *          day_during;
@property (nonatomic, strong) NSNumber   *          day_avg_speed;
@property (nonatomic, strong) NSNumber   *          day_max_speed;

@property (nonatomic, strong) NSNumber   *          night_dist;
@property (nonatomic, strong) NSNumber   *          night_during;
@property (nonatomic, strong) NSNumber   *          night_avg_speed;
@property (nonatomic, strong) NSNumber   *          night_max_speed;

@property (nonatomic, strong) NSString   *          weather;    //（小雨/大雨/雪）
@property (nonatomic, strong) NSString   *          temperature;
@property (nonatomic, strong) NSString   *          moisture;
@property (nonatomic, strong) NSString   *          wind;
@property (nonatomic, strong) NSNumber   *          pm25;

@property (nonatomic, strong) NSNumber   *          is_analyzed;

- (id)initWithTripId:(long)tripId;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface AnalyzeDrivingItem : NSObject

@property (nonatomic) long                          db_id;

// drive param
@property (nonatomic, strong) NSNumber   *          breaking_cnt;
@property (nonatomic, strong) NSNumber   *          hard_breaking_cnt;
@property (nonatomic, strong) NSNumber   *          max_breaking_begin_speed;   // max speed change over 5 seconds
@property (nonatomic, strong) NSNumber   *          max_breaking_end_speed;

@property (nonatomic, strong) NSNumber   *          acce_cnt;
@property (nonatomic, strong) NSNumber   *          hard_acce_cnt;
@property (nonatomic, strong) NSNumber   *          max_acce_begin_speed;       // max speed change over 5 seconds
@property (nonatomic, strong) NSNumber   *          max_acce_end_speed;

@property (nonatomic, strong) NSNumber   *          shortest_40;                // shortest during for speed from stationary to 40 km/h
@property (nonatomic, strong) NSNumber   *          shortest_60;                // shortest during for speed from stationary to 60 km/h
@property (nonatomic, strong) NSNumber   *          shortest_80;                // shortest during for speed from stationary to 80 km/h

@property (nonatomic, strong) NSNumber   *          is_analyzed;

- (id)initWithTripId:(long)tripId;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface AnalyzeTurningItem : NSObject

@property (nonatomic) long                          db_id;

// turning
@property (nonatomic, strong) NSNumber   *          left_turn_cnt;
@property (nonatomic, strong) NSNumber   *          left_turn_avg_speed;
@property (nonatomic, strong) NSNumber   *          left_turn_max_speed;

@property (nonatomic, strong) NSNumber   *          right_turn_cnt;
@property (nonatomic, strong) NSNumber   *          right_turn_avg_speed;
@property (nonatomic, strong) NSNumber   *          right_turn_max_speed;

@property (nonatomic, strong) NSNumber   *          turn_round_cnt;
@property (nonatomic, strong) NSNumber   *          turn_round_avg_speed;
@property (nonatomic, strong) NSNumber   *          turn_round_max_speed;

@property (nonatomic, strong) NSNumber   *          is_analyzed;

- (id)initWithTripId:(long)tripId;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface OnlineAnalyzeItem : NSObject

@property (nonatomic) long                          db_id;

// turning
@property (nonatomic, strong) NSNumber   *          start_date;
@property (nonatomic, strong) NSNumber   *          start_lat;
@property (nonatomic, strong) NSNumber   *          start_lon;
@property (nonatomic, strong) NSString   *          start_steet;
@property (nonatomic, strong) NSString   *          start_address;
@property (nonatomic, strong) NSNumber   *          start_loc_id;

@property (nonatomic, strong) NSNumber   *          end_date;
@property (nonatomic, strong) NSNumber   *          end_lat;
@property (nonatomic, strong) NSNumber   *          end_lon;
@property (nonatomic, strong) NSString   *          end_steet;
@property (nonatomic, strong) NSString   *          end_address;
@property (nonatomic, strong) NSNumber   *          end_loc_id;

@property (nonatomic, strong) NSNumber   *          trip_group_id;

- (id)initWithTripId:(long)tripId;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;

@end
