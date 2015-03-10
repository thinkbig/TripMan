//
//  EnvInfo+Fetcher.m
//  TripMan
//
//  Created by taq on 3/7/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "EnvInfo+Fetcher.h"

@implementation EnvInfo (Fetcher)

- (NSDictionary*) toJsonDict
{
    if (![self.is_analyzed boolValue]) {
        return nil;
    }
    
    NSMutableDictionary * mutableDict = [NSMutableDictionary dictionary];
    
    mutableDict[@"night_avg_speed"] = self.night_avg_speed;
    mutableDict[@"day_dist"] = self.day_dist;
    mutableDict[@"day_during"] = self.day_during;
    mutableDict[@"night_max_speed"] = self.night_max_speed;
    mutableDict[@"day_avg_speed"] = self.day_avg_speed;
    mutableDict[@"night_dist"] = self.night_dist;
    mutableDict[@"day_max_speed"] = self.day_max_speed;
    mutableDict[@"night_during"] = self.night_during;
    
    return mutableDict;
}

@end
