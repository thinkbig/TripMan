//
//  GPSOneTripAnalyzer.h
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSLogItem.h"
#import "CTRoute.h"

@interface GPSTripSummaryAnalyzer : NSObject

@property (nonatomic) CGFloat          total_dist;
@property (nonatomic) CGFloat          total_during;
@property (nonatomic) CGFloat          avg_speed;
@property (nonatomic) CGFloat          max_speed;

@property (nonatomic) CGFloat          traffic_jam_dist;
@property (nonatomic) CGFloat          traffic_jam_during;
@property (nonatomic) CGFloat          traffic_avg_speed;

@property (nonatomic) CGFloat          day_dist;
@property (nonatomic) CGFloat          day_during;
@property (nonatomic) CGFloat          day_avg_speed;
@property (nonatomic) CGFloat          day_max_speed;

@property (nonatomic) CGFloat          night_dist;
@property (nonatomic) CGFloat          night_during;
@property (nonatomic) CGFloat          night_avg_speed;
@property (nonatomic) CGFloat          night_max_speed;

@property (nonatomic, strong) CTRoute *         route;

- (void) updateGPSDataArray:(NSArray*)gpsLogs;

- (NSArray*) getTrafficJams;
- (NSString*) jsonRoute;

@end
