//
//  RouteOverlayView.h
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKOverlayGLBasicView.h"
#import "RouteOverlay.h"

@interface RouteOverlayView : BMKOverlayGLBasicView

@property (nonatomic, readonly) RouteOverlay *      routeOverlay;

- (id)initWithRouteOverlay:(RouteOverlay *)routeOverlay;

@end
