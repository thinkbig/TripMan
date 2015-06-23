//
//  BaiduMarkModel.m
//  TripMan
//
//  Created by taq on 11/14/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaiduMarkModel.h"

@implementation BaiduMarkLocationModel

- (BOOL)isEqual:(BaiduMarkLocationModel*)anObject
{
    return [self.lat isEqualToNumber:anObject.lat] && [self.lng isEqualToNumber:anObject.lng];
}

- (NSUInteger)hash
{
    return [self.lat hash] ^ [self.lng hash];
}

@end

@implementation BaiduMarkItemModel

- (BOOL)isEqual:(BaiduMarkItemModel*)anObject
{
    return ([self.type isEqualToNumber:anObject.type]) && ([self.location isEqual:anObject.location]) && ([self.name isEqualToString:anObject.name]);
}

- (NSUInteger)hash
{
    return [self.type hash] ^ [self.name hash] ^ [self.location hash];
}

- (CLLocation*) clLocation
{
    return [[CLLocation alloc] initWithLatitude:[self.location.lat doubleValue] longitude:[self.location.lng doubleValue]];
}

@end

@implementation BaiduMarkModel

@end