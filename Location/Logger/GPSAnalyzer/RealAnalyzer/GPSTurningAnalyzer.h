//
//  GPSTripEnvAnalyzer.h
//  Location
//
//  Created by taq on 10/21/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSLogItem.h"
#import "GPSOffTimeFilter.h"

@interface GPSTurningAnalyzer : NSObject

@property (nonatomic, strong) GPSOffTimeFilter *        filter;

@property (nonatomic) CGFloat        left_turn_cnt;
@property (nonatomic) CGFloat        left_turn_avg_speed;
@property (nonatomic) CGFloat        left_turn_max_speed;

@property (nonatomic) CGFloat        right_turn_cnt;
@property (nonatomic) CGFloat        right_turn_avg_speed;
@property (nonatomic) CGFloat        right_turn_max_speed;

@property (nonatomic) CGFloat        turn_round_cnt;
@property (nonatomic) CGFloat        turn_round_avg_speed;
@property (nonatomic) CGFloat        turn_round_max_speed;

- (void) updateGPSDataArray:(NSArray*)gpsLogs shouldSmooth:(BOOL)smooth;

@end
