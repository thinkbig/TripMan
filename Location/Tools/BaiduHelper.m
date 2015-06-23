//
//  BaiduHelper.m
//  TripMan
//
//  Created by taq on 2/11/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaiduHelper.h"

#define ANGLE(r)   (180.0*(r)/M_PI)

@implementation BaiduHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bdBundle = BDBUNDLE;
    }
    return self;
}

- (UIImage*) imageNamed:(NSString*)filename
{
    if (filename){
        NSString * fullPath = [[self.bdBundle resourcePath] stringByAppendingPathComponent:filename];
        return [UIImage imageWithContentsOfFile:fullPath];
    }
    return nil;
}

+ (CGFloat) mapAngleFromPoint:(CGPoint)fromPt toPoint:(CGPoint)toPt
{
    CGFloat dx = toPt.x - fromPt.x;
    CGFloat dy = toPt.y - fromPt.y;
    
    CGFloat angle = 0;
    if (0 == dy) {
        if (dx > 0) {
            angle = 90;
        } else {
            angle = -90;
        }
    } else {
        if (dy > 0) {
            angle = ANGLE(atan(dx/dy));
        } else {
            angle = ANGLE(atan(dx/dy)) + 180;
        }
    }
    return angle;
}

+ (CLLocationCoordinate2D) getCoordinateFromMapRectanglePoint:(double)x y:(double)y {
    BMKMapPoint swMapPoint = BMKMapPointMake(x, y);
    return BMKCoordinateForMapPoint(swMapPoint);
}

+ (CLLocationCoordinate2D)getNECoordinate:(BMKMapRect)mRect {
    return [self getCoordinateFromMapRectanglePoint:BMKMapRectGetMaxX(mRect) y:mRect.origin.y];
}

+ (CLLocationCoordinate2D)getNWCoordinate:(BMKMapRect)mRect {
    return [self getCoordinateFromMapRectanglePoint:BMKMapRectGetMinX(mRect) y:mRect.origin.y];
}

+ (CLLocationCoordinate2D)getSECoordinate:(BMKMapRect)mRect {
    return [self getCoordinateFromMapRectanglePoint:BMKMapRectGetMaxX(mRect) y:BMKMapRectGetMaxY(mRect)];
}

+ (CLLocationCoordinate2D)getSWCoordinate:(BMKMapRect)mRect {
    return [self getCoordinateFromMapRectanglePoint:mRect.origin.x y:BMKMapRectGetMaxY(mRect)];
}

+ (GeoRectBound*) getBoundingBox:(BMKMapRect)mRect
{
    GeoRectBound * bound = [GeoRectBound new];
    CLLocationCoordinate2D bottomLeft = [self getSWCoordinate:mRect];
    CLLocationCoordinate2D topRight = [self getNECoordinate:mRect];
    
    bound.minLat = MIN(bottomLeft.latitude, topRight.latitude);
    bound.maxLat = MAX(bottomLeft.latitude, topRight.latitude);
    bound.minLon = MIN(bottomLeft.longitude, topRight.longitude);
    bound.maxLon = MAX(bottomLeft.longitude, topRight.longitude);
    
    return bound;
}

@end
