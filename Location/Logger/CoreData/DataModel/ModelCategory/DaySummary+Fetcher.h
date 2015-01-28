//
//  DaySummary+Fetcher.h
//  TripMan
//
//  Created by taq on 1/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "DaySummary.h"

@interface DaySummary (Fetcher)

- (NSArray*) validTrips;
- (NSUInteger) validTripCount;

@end
