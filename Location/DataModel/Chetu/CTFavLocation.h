//
//  CTFavLocation.h
//  TripMan
//
//  Created by taq on 3/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTBaseLocation.h"
#import "ParkingRegion+Fetcher.h"

@interface CTFavLocation : CTBaseLocation

@property (nonatomic, strong) NSString<Optional> * parking_id;         // if this location is included in parking location

- (void) updateWithParkingRegion:(ParkingRegion*)region;

@end
