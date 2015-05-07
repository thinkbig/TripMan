//
//  BMKCityListInfo+Encode.m
//  TripMan
//
//  Created by taq on 5/7/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKCityListInfo+Encode.h"

@implementation BMKCityListInfo (Encode)

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        self.city = [decoder decodeObjectForKey:@"city"];
        self.num = [decoder decodeIntForKey:@"num"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_city forKey:@"city"];
    [encoder encodeInt:_num forKey:@"num"];
}

- (id)copyWithZone:(NSZone *)zone
{
    BMKCityListInfo *entry = [[[self class] allocWithZone:zone] init];
    entry.city = [_city copy];
    entry.num = _num;
    return entry;
}

@end
