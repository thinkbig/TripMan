//
//  CTBaseLocation.m
//  TripMan
//
//  Created by taq on 3/16/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTBaseLocation.h"

@implementation CTBaseLocation

- (BOOL)isEqual:(CTBaseLocation*)anObject
{
    return [self.lat isEqualToNumber:anObject.lat] && [self.lon isEqualToNumber:anObject.lon];
}

- (NSUInteger)hash
{
    return [self.lat hash] ^ [self.lon hash];
}

- (CLLocation*) clLocation
{
    return [[CLLocation alloc] initWithLatitude:[self.lat doubleValue] longitude:[self.lon doubleValue]];
}

@end
