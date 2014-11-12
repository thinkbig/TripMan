//
//  GPSTripEnvAnalyzer.m
//  Location
//
//  Created by taq on 10/21/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSTurningAnalyzer.h"
#import "GPSOffTimeFilter.h"

@interface GPSTurningAnalyzer ()

@end


@implementation GPSTurningAnalyzer


- (void) updateGPSDataArray:(NSArray*)gpsLogs
{
    // init
    self.left_turn_cnt = 0;
    self.left_turn_avg_speed = 0;
    self.left_turn_max_speed = 0;
    self.right_turn_cnt = 0;
    self.right_turn_avg_speed = 0;
    self.right_turn_max_speed = 0;
    self.turn_round_cnt = 0;
    self.turn_round_avg_speed = 0;
    self.turn_round_max_speed = 0;
    
    if (gpsLogs.count < 2) {
        return;
    }
    
    GPSOffTimeFilter * filter = [GPSOffTimeFilter new];
    [filter calGPSDataForTurning:gpsLogs smoothFirst:YES];
    NSArray * turningParam = [filter turningParams];
    
    CGFloat tolLeftTurnSpeed = 0;
    CGFloat tolRightTurnSpeed = 0;
    CGFloat tolTurnAroundSpeed = 0;
    for (GPSTurningItem * item in turningParam) {
        if (item.eStat == eTurningLeft) {
            self.left_turn_cnt++;
            self.left_turn_max_speed = MAX(self.left_turn_max_speed, item.maxSpeed);
            tolLeftTurnSpeed += item.avgSpeed;
        } else if (item.eStat == eTurningRight) {
            self.right_turn_cnt++;
            self.right_turn_max_speed = MAX(self.right_turn_max_speed, item.maxSpeed);
            tolRightTurnSpeed += item.avgSpeed;
        } else if (item.eStat == eTurningAround) {
            self.turn_round_cnt++;
            self.turn_round_max_speed = MAX(self.turn_round_max_speed, item.maxSpeed);
            tolTurnAroundSpeed += item.avgSpeed;
        }
    }
    if (self.left_turn_cnt > 0) {
        self.left_turn_avg_speed = tolLeftTurnSpeed/self.left_turn_cnt;
    }
    if (self.right_turn_cnt > 0) {
        self.right_turn_avg_speed = tolRightTurnSpeed/self.right_turn_cnt;
    }
    if (self.turn_round_cnt > 0) {
        self.turn_round_avg_speed = tolTurnAroundSpeed/self.turn_round_cnt;
    }
}

@end
