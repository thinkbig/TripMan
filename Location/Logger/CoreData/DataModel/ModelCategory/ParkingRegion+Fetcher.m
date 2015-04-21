//
//  ParkingRegion+Fetcher.m
//  TripMan
//
//  Created by taq on 1/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "ParkingRegion+Fetcher.h"

@implementation ParkingRegion (Fetcher)

- (NSString*) nameWithDefault:(NSString*)defaultName {
    if (self.user_mark.length > 0) {
        return self.user_mark;
    } else if (self.nearby_poi.length > 0) {
        return self.nearby_poi;
    }
    return defaultName;
}

- (CLLocation*) centerLocation
{
    return [[CLLocation alloc] initWithLatitude:[self.center_lat doubleValue] longitude:[self.center_lon doubleValue]];
}

- (CLLocationCoordinate2D) centerCoordinate
{
    return CLLocationCoordinate2DMake([self.center_lat doubleValue], [self.center_lon doubleValue]);
}

- (CGFloat) distanseFrom:(ParkingRegion*)region
{
    if (nil == region) {
        return -1;
    } else if (self == region) {
        return 0;
    }
    return [[self centerLocation] distanceFromLocation:[region centerLocation]];
}

- (NSInteger) driveEndCount
{
    NSUInteger tripCnt = 0;
    for (RegionGroup * group in self.group_owner_ed) {
        tripCnt += group.trips.count;
    }
    return tripCnt;
}

- (NSDictionary*) toJsonDict
{
    NSMutableDictionary * mutableDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.center_lat, @"gps_lat", self.center_lon, @"gps_lon", nil];
    
    if (self.parking_id.length > 0) mutableDict[@"pid"] = self.parking_id;
    if (self.nearby_poi.length > 0) mutableDict[@"nearby_poi"] = self.nearby_poi;
    if (self.user_mark.length > 0) mutableDict[@"user_mark"] = self.user_mark;
    if (self.province.length > 0) mutableDict[@"province"] = self.province;
    if (self.city.length > 0) mutableDict[@"city"] = self.city;
    if (self.district.length > 0) mutableDict[@"district"] = self.district;
    if (self.street.length > 0) mutableDict[@"street"] = self.street;
    if (self.street_num.length > 0) mutableDict[@"street_num"] = self.street_num;

    return mutableDict;
}

@end
