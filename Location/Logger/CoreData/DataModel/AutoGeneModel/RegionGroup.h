//
//  RegionGroup.h
//  TripMan
//
//  Created by taq on 11/29/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ParkingRegion, TripSummary;

@interface RegionGroup : NSManagedObject

@property (nonatomic, retain) NSNumber * best_dist;
@property (nonatomic, retain) NSNumber * best_during;
@property (nonatomic, retain) NSNumber * best_jam;
@property (nonatomic, retain) NSDate * best_start;
@property (nonatomic, retain) NSNumber * group;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * is_temp;
@property (nonatomic, retain) NSNumber * relative_trips_cnt;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) ParkingRegion *end_region;
@property (nonatomic, retain) ParkingRegion *start_region;
@property (nonatomic, retain) NSSet *trips;
@end

@interface RegionGroup (CoreDataGeneratedAccessors)

- (void)addTripsObject:(TripSummary *)value;
- (void)removeTripsObject:(TripSummary *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;

@end
