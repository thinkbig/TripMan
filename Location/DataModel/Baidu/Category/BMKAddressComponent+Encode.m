//
//  BMKAddressComponent+Encode.m
//  TripMan
//
//  Created by taq on 4/22/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKAddressComponent+Encode.h"

@implementation BMKAddressComponent (Encode)

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        self.streetNumber = [decoder decodeObjectForKey:@"streetNumber"];
        self.streetName = [decoder decodeObjectForKey:@"streetName"];
        self.district = [decoder decodeObjectForKey:@"district"];
        self.city = [decoder decodeObjectForKey:@"city"];
        self.province = [decoder decodeObjectForKey:@"province"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_streetNumber forKey:@"streetNumber"];
    [encoder encodeObject:_streetName forKey:@"streetName"];
    [encoder encodeObject:_district forKey:@"district"];
    [encoder encodeObject:_city forKey:@"city"];
    [encoder encodeObject:_province forKey:@"province"];
}

- (id)copyWithZone:(NSZone *)zone
{
    BMKAddressComponent *entry = [[[self class] allocWithZone:zone] init];
    entry.streetNumber = [_streetNumber copy];
    entry.streetName = [_streetName copy];
    entry.district = [_district copy];
    entry.city = [_city copy];
    entry.province = [_province copy];
    return entry;
}

@end
