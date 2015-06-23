//
//  RouteOverlay.h
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKShape.h"

@interface RouteOverlay : BMKShape <BMKOverlay> {
    BMKMapRect _boundingMapRect;
}

@property (nonatomic, readonly) BMKMapRect boundingMapRect;
@property (nonatomic, readonly) BMKMapPoint* points;
@property (nonatomic, readonly) NSUInteger pointCount;

- (id)initWithPoints:(BMKMapPoint *)points count:(NSUInteger)count;

+ (RouteOverlay *)routeWithPoints:(BMKMapPoint *)points count:(NSUInteger)count;

@end
