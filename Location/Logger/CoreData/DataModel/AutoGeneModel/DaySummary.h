//
//  DaySummary.h
//  TripMan
//
//  Created by taq on 4/28/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MonthSummary, TripSummary, WeekSummary;

@interface DaySummary : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSNumber * avg_speed;
@property (nonatomic, retain) NSDate * date_day;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * jam_dist;
@property (nonatomic, retain) NSNumber * jam_during;
@property (nonatomic, retain) NSNumber * max_speed;
@property (nonatomic, retain) NSNumber * total_dist;
@property (nonatomic, retain) NSNumber * total_during;
@property (nonatomic, retain) NSNumber * traffic_heavy_jam_cnt;
@property (nonatomic, retain) NSNumber * traffic_light_jam_cnt;
@property (nonatomic, retain) NSNumber * traffic_light_waiting;
@property (nonatomic, retain) NSSet *all_trips;
@property (nonatomic, retain) MonthSummary *month_summary;
@property (nonatomic, retain) WeekSummary *week_summary;
@property (nonatomic, retain) NSManagedObject *extend;
@end

@interface DaySummary (CoreDataGeneratedAccessors)

- (void)addAll_tripsObject:(TripSummary *)value;
- (void)removeAll_tripsObject:(TripSummary *)value;
- (void)addAll_trips:(NSSet *)values;
- (void)removeAll_trips:(NSSet *)values;

@end
