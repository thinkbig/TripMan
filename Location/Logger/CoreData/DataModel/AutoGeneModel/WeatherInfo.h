//
//  WeatherInfo.h
//  TripMan
//
//  Created by taq on 4/28/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TripSummary;

@interface WeatherInfo : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSDate * date_day;
@property (nonatomic, retain) NSNumber * hour_period;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSString * moisture;
@property (nonatomic, retain) NSString * pm25;
@property (nonatomic, retain) NSString * temperature;
@property (nonatomic, retain) NSString * weather;
@property (nonatomic, retain) NSString * wind;
@property (nonatomic, retain) NSSet *trip_owner;
@property (nonatomic, retain) NSManagedObject *extend;
@end

@interface WeatherInfo (CoreDataGeneratedAccessors)

- (void)addTrip_ownerObject:(TripSummary *)value;
- (void)removeTrip_ownerObject:(TripSummary *)value;
- (void)addTrip_owner:(NSSet *)values;
- (void)removeTrip_owner:(NSSet *)values;

@end
