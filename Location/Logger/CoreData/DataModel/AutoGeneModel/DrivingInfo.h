//
//  DrivingInfo.h
//  Location
//
//  Created by taq on 11/7/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TripSummary;

@interface DrivingInfo : NSManagedObject

@property (nonatomic, retain) NSNumber * acce_cnt;
@property (nonatomic, retain) NSNumber * breaking_cnt;
@property (nonatomic, retain) NSNumber * hard_acce_cnt;
@property (nonatomic, retain) NSNumber * hard_breaking_cnt;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * max_acce_begin_speed;
@property (nonatomic, retain) NSNumber * max_acce_end_speed;
@property (nonatomic, retain) NSNumber * max_breaking_begin_speed;
@property (nonatomic, retain) NSNumber * max_breaking_end_speed;
@property (nonatomic, retain) NSNumber * shortest_40;
@property (nonatomic, retain) NSNumber * shortest_60;
@property (nonatomic, retain) NSNumber * shortest_80;
@property (nonatomic, retain) TripSummary *trip_owner;

@end
