//
//  GPSAcceleratorAnalyzer.h
//  Location
//
//  Created by taq on 10/21/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPSAcceleratorAnalyzer : NSObject

@property (nonatomic) NSInteger        breaking_cnt;
@property (nonatomic) NSInteger        hard_breaking_cnt;
@property (nonatomic) CGFloat          max_breaking_begin_speed;   // max speed change over 5 seconds
@property (nonatomic) CGFloat          max_breaking_end_speed;

@property (nonatomic) NSInteger        acce_cnt;
@property (nonatomic) NSInteger        hard_acce_cnt;
@property (nonatomic) CGFloat          max_acce_begin_speed;       // max speed change over 5 seconds
@property (nonatomic) CGFloat          max_acce_end_speed;

@property (nonatomic) CGFloat          shortest_40;                // shortest during for speed from stationary to 40 km/h
@property (nonatomic) CGFloat          shortest_60;                // shortest during for speed from stationary to 60 km/h
@property (nonatomic) CGFloat          shortest_80;                // shortest during for speed from stationary to 80 km/h

@property (nonatomic) CGFloat          during_0_30;                 // drive during of speed range
@property (nonatomic) CGFloat          during_30_60;
@property (nonatomic) CGFloat          during_60_100;
@property (nonatomic) CGFloat          during_100_NA;

- (void) updateGPSDataArray:(NSArray*)gpsLogs;

@end
