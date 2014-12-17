//
//  TrafficJam.h
//  TripMan
//
//  Created by taq on 12/16/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TripSummary;

@interface TrafficJam : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSDate * end_date;
@property (nonatomic, retain) NSNumber * end_lat;
@property (nonatomic, retain) NSNumber * end_lon;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * near_traffic_light;
@property (nonatomic, retain) NSDate * start_date;
@property (nonatomic, retain) NSNumber * start_lat;
@property (nonatomic, retain) NSNumber * start_lon;
@property (nonatomic, retain) NSNumber * traffic_avg_speed;
@property (nonatomic, retain) NSNumber * traffic_jam_dist;
@property (nonatomic, retain) NSNumber * traffic_jam_during;
@property (nonatomic, retain) TripSummary *trip_owner;

@end
