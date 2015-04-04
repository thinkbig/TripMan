//
//  GeoRectBound.m
//  TripMan
//
//  Created by taq on 3/22/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GeoRectBound.h"

@implementation GeoRectBound

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxLat = -90;
        self.maxLon = -180;
        self.minLat = 90;
        self.minLon = 180;
    }
    return self;
}

- (void) updateBoundsWithCoor:(CLLocationCoordinate2D)coor
{
    if(coor.latitude > self.maxLat)
        self.maxLat = coor.latitude;
    if(coor.latitude < self.minLat)
        self.minLat = coor.latitude;
    if(coor.longitude > self.maxLon)
        self.maxLon = coor.longitude;
    if(coor.longitude < self.minLon)
        self.minLon = coor.longitude;
}

- (BMKCoordinateRegion) baiduRegion
{
    BMKCoordinateRegion bdRegion;
    bdRegion.center.latitude     = (self.maxLat + self.minLat) / 2.0 - 0.007;
    bdRegion.center.longitude    = (self.maxLon + self.minLon) / 2.0;
    bdRegion.span.latitudeDelta  = (self.maxLat - self.minLat) / 2.0 * 1.3;
    bdRegion.span.longitudeDelta = (self.maxLon - self.minLon) / 2.0 * 1.4;
    
    return bdRegion;
}

- (MKCoordinateRegion) mapRegion
{
    MKCoordinateRegion region;
    region.center.latitude     = (self.maxLat + self.minLat) / 2.0 - 0.007;
    region.center.longitude    = (self.maxLon + self.minLon) / 2.0;
    region.span.latitudeDelta  = (self.maxLat - self.minLat) / 2.0 + 0.018;
    region.span.longitudeDelta = (self.maxLon - self.minLon) / 2.0 + 0.018;
    
    return region;
}

@end
