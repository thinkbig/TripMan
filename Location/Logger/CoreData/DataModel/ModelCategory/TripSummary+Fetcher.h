//
//  TripSummary+Fetcher.h
//  TripMan
//
//  Created by taq on 2/4/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripSummary.h"

#define TRAFFIC_YELLOW_THRESHOLD            (5*60)
#define TRAFFIC_RED_THRESHOLD               (10*60)

// refer to TripSummary.quality
typedef NS_ENUM(NSUInteger, eTripQuality) {
    eTripQualityUnknow = 0,
    eTripQualityGood,
    eTripQualityMedium,
    eTripQualityLow,
    eTripQualityPoor
};

@interface TripSummary (Fetcher)

- (NSDictionary*) toJsonDict;
- (CTRoute*) tripRoute;

@end
