//
//  GPlaceModel.m
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GPlaceModel.h"

@implementation GLocModel

- (CLLocationCoordinate2D) coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation GSnapPtModel

- (CLLocationCoordinate2D) coordinate {
    return [self.location coordinate];
}

@end
