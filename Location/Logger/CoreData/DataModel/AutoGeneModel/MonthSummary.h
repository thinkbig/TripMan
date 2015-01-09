//
//  MonthSummary.h
//  TripMan
//
//  Created by taq on 1/7/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DaySummary, TripSummary;

@interface MonthSummary : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSDate * date_month;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * jam_dist;
@property (nonatomic, retain) NSNumber * jam_during;
@property (nonatomic, retain) NSNumber * max_speed;
@property (nonatomic, retain) NSNumber * total_dist;
@property (nonatomic, retain) NSNumber * total_during;
@property (nonatomic, retain) NSNumber * traffic_heavy_jam_cnt;
@property (nonatomic, retain) NSNumber * trip_cnt;
@property (nonatomic, retain) NSSet *all_days;
@property (nonatomic, retain) TripSummary *trip_most_dist;
@property (nonatomic, retain) TripSummary *trip_most_during;
@property (nonatomic, retain) TripSummary *trip_most_jam_during;
@end

@interface MonthSummary (CoreDataGeneratedAccessors)

- (void)addAll_daysObject:(DaySummary *)value;
- (void)removeAll_daysObject:(DaySummary *)value;
- (void)addAll_days:(NSSet *)values;
- (void)removeAll_days:(NSSet *)values;

@end
