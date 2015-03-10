//
//  DrivingInfo+Fetcher.m
//  TripMan
//
//  Created by taq on 3/7/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "DrivingInfo+Fetcher.h"

@implementation DrivingInfo (Fetcher)

- (NSDictionary*) toJsonDict
{
    if (![self.is_analyzed boolValue]) {
        return nil;
    }
    
    NSMutableDictionary * mutableDict = [NSMutableDictionary dictionary];
    
    mutableDict[@"breaking_cnt"] = self.breaking_cnt;
    mutableDict[@"shortest_80"] = self.shortest_80;
    mutableDict[@"during_30_60"] = self.during_30_60;
    mutableDict[@"during_0_30"] = self.during_0_30;
    mutableDict[@"shortest_60"] = self.shortest_60;
    mutableDict[@"max_breaking_end_speed"] = self.max_breaking_end_speed;
    mutableDict[@"acce_cnt"] = self.acce_cnt;
    mutableDict[@"max_acce_end_speed"] = self.max_acce_end_speed;
    mutableDict[@"shortest_40"] = self.shortest_40;
    mutableDict[@"hard_breaking_cnt"] = self.hard_breaking_cnt;
    mutableDict[@"max_breaking_begin_speed"] = self.max_breaking_begin_speed;
    mutableDict[@"during_100_NA"] = self.during_100_NA;
    mutableDict[@"during_60_100"] = self.during_60_100;
    mutableDict[@"max_acce_begin_speed"] = self.max_acce_begin_speed;
    
    return mutableDict;
}

@end
