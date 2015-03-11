//
//  TrafficJam+Fetcher.m
//  TripMan
//
//  Created by taq on 3/8/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TrafficJam+Fetcher.h"

@implementation TrafficJam (Fetcher)

- (NSDictionary*) toJsonDict
{
    // 这里is_analyzed，只对near_traffic_light这个参数有意义
    
    NSMutableDictionary * mutableDict = [NSMutableDictionary dictionary];
    
    mutableDict[@"st"] = @[@((unsigned long long)[self.start_date timeIntervalSince1970]), self.start_lat, self.start_lon];
    mutableDict[@"ed"] = @[@((unsigned long long)[self.end_date timeIntervalSince1970]), self.end_lat, self.end_lon];
    mutableDict[@"avg_speed"] = self.traffic_avg_speed;
    
    return mutableDict;
}

@end
