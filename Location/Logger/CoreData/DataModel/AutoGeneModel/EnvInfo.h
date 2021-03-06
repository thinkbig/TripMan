//
//  EnvInfo.h
//  TripMan
//
//  Created by taq on 4/28/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TripSummary;

@interface EnvInfo : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSNumber * day_avg_speed;
@property (nonatomic, retain) NSNumber * day_dist;
@property (nonatomic, retain) NSNumber * day_during;
@property (nonatomic, retain) NSNumber * day_max_speed;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * night_avg_speed;
@property (nonatomic, retain) NSNumber * night_dist;
@property (nonatomic, retain) NSNumber * night_during;
@property (nonatomic, retain) NSNumber * night_max_speed;
@property (nonatomic, retain) TripSummary *trip_owner;
@property (nonatomic, retain) NSManagedObject *extend;

@end
