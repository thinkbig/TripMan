//
//  TrafficJam+Fetcher.h
//  TripMan
//
//  Created by taq on 3/8/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TrafficJam.h"

@interface TrafficJam (Fetcher)

- (NSDictionary*) toJsonDict;

- (CLLocationCoordinate2D) stCoordinate;
- (CLLocationCoordinate2D) edCoordinate;

- (CTBaseLocation*) stCTLocation;
- (CTBaseLocation*) edCTLocation;

@end
