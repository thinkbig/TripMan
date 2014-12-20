//
//  TurningInfo.h
//  TripMan
//
//  Created by taq on 12/18/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TripSummary;

@interface TurningInfo : NSManagedObject

@property (nonatomic, retain) NSData * addi_data;
@property (nonatomic, retain) NSString * addi_info;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * left_turn_avg_speed;
@property (nonatomic, retain) NSNumber * left_turn_cnt;
@property (nonatomic, retain) NSNumber * left_turn_max_speed;
@property (nonatomic, retain) NSNumber * right_turn_avg_speed;
@property (nonatomic, retain) NSNumber * right_turn_cnt;
@property (nonatomic, retain) NSNumber * right_turn_max_speed;
@property (nonatomic, retain) NSNumber * turn_round_avg_speed;
@property (nonatomic, retain) NSNumber * turn_round_cnt;
@property (nonatomic, retain) NSNumber * turn_round_max_speed;
@property (nonatomic, retain) TripSummary *trip_owner;

@end
