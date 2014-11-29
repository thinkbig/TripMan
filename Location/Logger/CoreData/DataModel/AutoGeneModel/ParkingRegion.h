//
//  ParkingRegion.h
//  TripMan
//
//  Created by taq on 11/29/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RegionGroup;

@interface ParkingRegion : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * center_lat;
@property (nonatomic, retain) NSNumber * center_lon;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSString * district;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * is_temp;
@property (nonatomic, retain) NSString * nearby_poi;
@property (nonatomic, retain) NSString * province;
@property (nonatomic, retain) NSNumber * rate;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * street_num;
@property (nonatomic, retain) NSString * user_mark;
@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSSet *group_owner_ed;
@property (nonatomic, retain) NSSet *group_owner_st;
@end

@interface ParkingRegion (CoreDataGeneratedAccessors)

- (void)addGroup_owner_edObject:(RegionGroup *)value;
- (void)removeGroup_owner_edObject:(RegionGroup *)value;
- (void)addGroup_owner_ed:(NSSet *)values;
- (void)removeGroup_owner_ed:(NSSet *)values;

- (void)addGroup_owner_stObject:(RegionGroup *)value;
- (void)removeGroup_owner_stObject:(RegionGroup *)value;
- (void)addGroup_owner_st:(NSSet *)values;
- (void)removeGroup_owner_st:(NSSet *)values;

@end
