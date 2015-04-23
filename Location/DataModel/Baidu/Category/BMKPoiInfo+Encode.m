//
//  BMKPoiInfo+Encode.m
//  TripMan
//
//  Created by taq on 4/22/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKPoiInfo+Encode.h"

@implementation BMKPoiInfo (Encode)

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.uid = [decoder decodeObjectForKey:@"uid"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.city = [decoder decodeObjectForKey:@"city"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
        self.postcode = [decoder decodeObjectForKey:@"postcode"];
        self.epoitype = [decoder decodeIntForKey:@"epoitype"];
        
        self.pt = CLLocationCoordinate2DMake([decoder decodeDoubleForKey:@"pt_lat"], [decoder decodeDoubleForKey:@"pt_lon"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_uid forKey:@"uid"];
    [encoder encodeObject:_address forKey:@"address"];
    [encoder encodeObject:_city forKey:@"city"];
    [encoder encodeObject:_phone forKey:@"phone"];
    [encoder encodeObject:_postcode forKey:@"postcode"];
    [encoder encodeInt:_epoitype forKey:@"epoitype"];
    
    [encoder encodeDouble:_pt.latitude forKey:@"pt_lat"];
    [encoder encodeDouble:_pt.longitude forKey:@"pt_lon"];
}

- (id)copyWithZone:(NSZone *)zone
{
    BMKPoiInfo *entry = [[[self class] allocWithZone:zone] init];
    entry.name = [_name copy];
    entry.uid = [_uid copy];
    entry.address = [_address copy];
    entry.city = [_city copy];
    entry.phone = [_phone copy];
    entry.postcode = [_postcode copy];
    entry.epoitype = _epoitype;
    entry.pt = _pt;
    return entry;
}

@end
