//
//  TripSummary.h
//  TripMan
//
//  Created by taq on 12/4/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DaySummary, DrivingInfo, EnvInfo, RegionGroup, TrafficJam, TurningInfo, WeatherInfo;

@interface TripSummary : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSNumber * avg_speed;
@property (nonatomic, retain) NSDate * end_date;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * max_speed;
@property (nonatomic, retain) NSDate * start_date;
@property (nonatomic, retain) NSNumber * total_dist;
@property (nonatomic, retain) NSNumber * total_during;
@property (nonatomic, retain) NSNumber * traffic_avg_speed;
@property (nonatomic, retain) NSNumber * traffic_jam_dist;
@property (nonatomic, retain) NSNumber * traffic_jam_during;
@property (nonatomic, retain) NSNumber * traffic_light_jam_cnt;
@property (nonatomic, retain) NSNumber * traffic_light_tol_cnt;
@property (nonatomic, retain) NSNumber * traffic_heavy_jam_cnt;
@property (nonatomic, retain) DaySummary *day_summary;
@property (nonatomic, retain) DrivingInfo *driving_info;
@property (nonatomic, retain) EnvInfo *environment;
@property (nonatomic, retain) RegionGroup *region_group;
@property (nonatomic, retain) NSSet *traffic_jams;
@property (nonatomic, retain) TurningInfo *turning_info;
@property (nonatomic, retain) WeatherInfo *weather;
@end

@interface TripSummary (CoreDataGeneratedAccessors)

- (void)addTraffic_jamsObject:(TrafficJam *)value;
- (void)removeTraffic_jamsObject:(TrafficJam *)value;
- (void)addTraffic_jams:(NSSet *)values;
- (void)removeTraffic_jams:(NSSet *)values;

@end
