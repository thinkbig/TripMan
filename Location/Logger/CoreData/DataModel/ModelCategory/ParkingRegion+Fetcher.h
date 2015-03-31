//
//  ParkingRegion+Fetcher.h
//  TripMan
//
//  Created by taq on 1/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "ParkingRegion.h"
#import "CTFavLocation.h"

@interface ParkingRegion (Fetcher)

- (NSString*) nameWithDefault:(NSString*)defaultName;

- (CLLocation*) centerLocation;
- (CLLocationCoordinate2D) centerCoordinate;
- (CTFavLocation*) toFavLocation;

- (CGFloat) distanseFrom:(ParkingRegion*)region;

- (NSDictionary*) toJsonDict;

@end
