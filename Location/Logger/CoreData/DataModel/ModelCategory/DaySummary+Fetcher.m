//
//  DaySummary+Fetcher.m
//  TripMan
//
//  Created by taq on 1/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "DaySummary+Fetcher.h"

@implementation DaySummary (Fetcher)

- (NSArray*) validTrips
{
    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:self.all_trips.count];
    for (TripSummary * sum in self.all_trips) {
        if ([sum.is_valid boolValue]) {
            [arr addObject:sum];
        }
    }
    return arr;
}

- (NSUInteger) validTripCount
{
    NSUInteger cnt = 0;
    for (TripSummary * sum in self.all_trips) {
        if ([sum.is_valid boolValue]) {
            cnt++;
        }
    }
    return cnt;
}

@end
