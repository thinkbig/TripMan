//
//  CTFavLocation.m
//  TripMan
//
//  Created by taq on 3/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTFavLocation.h"

@implementation CTFavLocation

- (void) updateWithParkingRegion:(ParkingRegion*)region
{
    self.lat = region.center_lat;
    self.lon = region.center_lon;
    self.name = [region nameWithDefault:@"未知地点"];
    self.street = region.street;
    self.parking_id = region.parking_id;
}

@end
