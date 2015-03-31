//
//  TurningInfo+Fetcher.m
//  TripMan
//
//  Created by taq on 3/6/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TurningInfo+Fetcher.h"

@implementation TurningInfo (Fetcher)

- (NSDictionary*) toJsonDict
{
    if (![self.is_analyzed boolValue]) {
        return nil;
    }
    
    NSMutableDictionary * mutableDict = [NSMutableDictionary dictionary];
    
    NSArray * pts = [self turningPts];
    if (pts) {
        mutableDict[@"points"] = pts;
    }
    
    mutableDict[@"turn_round_cnt"] = self.turn_round_cnt;
    mutableDict[@"turn_round_max_speed"] = self.turn_round_max_speed;
    mutableDict[@"left_turn_cnt"] = self.left_turn_cnt;
    mutableDict[@"right_turn_max_speed"] = self.right_turn_max_speed;
    mutableDict[@"turn_round_avg_speed"] = self.turn_round_avg_speed;
    mutableDict[@"right_turn_cnt"] = self.right_turn_cnt;
    mutableDict[@"left_turn_avg_speed"] = self.left_turn_avg_speed;
    mutableDict[@"right_turn_avg_speed"] = self.right_turn_avg_speed;
    mutableDict[@"left_turn_max_speed"] = self.left_turn_max_speed;
    
    return mutableDict;
}

- (NSArray*) turningPts
{
    if (self.addi_data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:self.addi_data];
    }
    return nil;
}

@end
