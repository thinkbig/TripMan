//
//  TripSummary+Fetcher.h
//  TripMan
//
//  Created by taq on 2/4/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripSummary.h"

typedef NS_ENUM(NSUInteger, eTrafficStatus) {
    eTrafficGreen = 0,
    eTrafficYellow,
    eTrafficRed
};

#define TRAFFIC_YELLOW_THRESHOLD            (5*60)
#define TRAFFIC_RED_THRESHOLD               (10*60)

@interface TripSummary (Fetcher)

- (eTrafficStatus) trafficStatus;
- (NSDictionary*) toJsonDict;

- (NSArray*) wayPoints;

@end
