//
//  GeoRectBound.h
//  TripMan
//
//  Created by taq on 3/22/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface GeoRectBound : NSObject

@property (nonatomic) CGFloat   minLat;
@property (nonatomic) CGFloat   maxLat;
@property (nonatomic) CGFloat   minLon;
@property (nonatomic) CGFloat   maxLon;

- (void) updateBoundsWithCoor:(CLLocationCoordinate2D)coor;
- (BMKCoordinateRegion) baiduRegion;
- (MKCoordinateRegion) mapRegion;

@end
