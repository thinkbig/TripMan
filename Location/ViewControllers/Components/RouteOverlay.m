//
//  RouteOverlay.m
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "RouteOverlay.h"

@implementation RouteOverlay

+ (RouteOverlay *)routeWithPoints:(BMKMapPoint *)points count:(NSUInteger)count
{
    RouteOverlay* polyline = [[RouteOverlay alloc] initWithPoints:points count:count];
    return polyline;
}

+ (BMKMapRect) MapRectUnionWithPoint:(BMKMapRect)rect1 point:(BMKMapPoint)point
{
    BMKMapRect rcRet;
    double tmp = MAX(rect1.origin.x+rect1.size.width, point.x);
    rcRet.origin.x = MIN(rect1.origin.x, point.x);
    rcRet.size.width = tmp-rcRet.origin.x;
    tmp = MAX(rect1.origin.y+rect1.size.height, point.y);
    rcRet.origin.y = MIN(rect1.origin.y, point.y);
    rcRet.size.height = tmp-rcRet.origin.y;
    return rcRet;
}


- (id) initWithPoints:(BMKMapPoint *)points count:(NSUInteger)count
{
    self = [super init];
    if (points != nil && count > 0) {
        _points = new BMKMapPoint[count];
        if (_points == nil) {
            return self;
        }
        memcpy(_points, points, sizeof(BMKMapPoint)*count);
        
        _pointCount = count;
    }
    return self;
}

- (BMKMapRect) boundingMapRect
{
    if (_points != nil && _pointCount > 0) {
        _boundingMapRect.origin = _points[0];
        _boundingMapRect.size.width = 0;
        _boundingMapRect.size.height = 0;
        for (int i = 0; i < _pointCount; i++) {
            _boundingMapRect = [RouteOverlay MapRectUnionWithPoint:_boundingMapRect point:_points[i]];
        }
    }
    if (_boundingMapRect.size.width == 0) {
        _boundingMapRect.size.width = 1;
    }
    if (_boundingMapRect.size.height == 0) {
        _boundingMapRect.size.height = 1;
    }
    
    return _boundingMapRect;
}

@end
