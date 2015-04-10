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

- (CLLocationCoordinate2D) coordinate
{
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lon doubleValue]);
}

- (CLLocation*) clLocation
{
    return [[CLLocation alloc] initWithLatitude:[self.lat doubleValue] longitude:[self.lon doubleValue]];
}

- (void) updateWithCoordinate:(CLLocationCoordinate2D)coor
{
    self.lat = @(coor.latitude);
    self.lon = @(coor.longitude);
}

- (BOOL) updateWithCoordinateStr:(NSString*)coorStr
{
    NSArray * coorNum = [coorStr componentsSeparatedByString:@","];
    if (coorNum.count == 2) {
        self.lon = @([coorNum[0] floatValue]);
        self.lat = @([coorNum[1] floatValue]);
        return YES;
    }
    return NO;
}

- (CGFloat) distanceFrom:(CTBaseLocation*)loc {
    return [[self clLocation] distanceFromLocation:[loc clLocation]];
}

@end
