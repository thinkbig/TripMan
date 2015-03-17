//
//  ParkingRegion+Fetcher.h
//  TripMan
//
//  Created by taq on 1/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "ParkingRegion.h"

@interface ParkingRegion (Fetcher)

- (NSString*) nameWithDefault:(NSString*)defaultName;
- (CLLocation*) centerLocation;
- (CGFloat) distanseFrom:(ParkingRegion*)region;

- (NSDictionary*) toJsonDict;

@end
