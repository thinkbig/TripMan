//
//  BMKReverseGeoCodeResult+Encode.m
//  TripMan
//
//  Created by taq on 4/22/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKReverseGeoCodeResult+Encode.h"
#import "BMKAddressComponent+Encode.h"
#import "BMKPoiInfo+Encode.h"

@implementation BMKReverseGeoCodeResult (Encode)

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        self.addressDetail = [decoder decodeObjectForKey:@"addressDetail"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.poiList = [decoder decodeObjectForKey:@"poiList"];
        
        self.location = CLLocationCoordinate2DMake([decoder decodeDoubleForKey:@"location_lat"], [decoder decodeDoubleForKey:@"location_lon"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_addressDetail forKey:@"addressDetail"];
    [encoder encodeObject:_address forKey:@"address"];
    [encoder encodeObject:_poiList forKey:@"poiList"];
    
    [encoder encodeDouble:_location.latitude forKey:@"location_lat"];
    [encoder encodeDouble:_location.longitude forKey:@"location_lon"];
}

- (id)copyWithZone:(NSZone *)zone
{
    BMKReverseGeoCodeResult *entry = [[[self class] allocWithZone:zone] init];
    entry.addressDetail = [_addressDetail copy];
    entry.address = [_address copy];
    entry.poiList = [_poiList copy];
    entry.location = _location;
    return entry;
}

@end
