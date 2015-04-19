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

- (CLLocationCoordinate2D) stCoordinate
{
    return CLLocationCoordinate2DMake([self.start_lat doubleValue], [self.start_lon doubleValue]);
}

- (CLLocationCoordinate2D) edCoordinate
{
    return CLLocationCoordinate2DMake([self.end_lat doubleValue], [self.end_lon doubleValue]);
}

- (CTBaseLocation*) stCTLocation
{
    CTBaseLocation * loc = [CTBaseLocation new];
    loc.ts = self.start_date;
    loc.lat = self.start_lat;
    loc.lon = self.start_lon;
    
    return loc;
}

- (CTBaseLocation*) edCTLocation
{
    CTBaseLocation * loc = [CTBaseLocation new];
    loc.ts = self.end_date;
    loc.lat = self.end_lat;
    loc.lon = self.end_lon;
    
    return loc;
}

@end
