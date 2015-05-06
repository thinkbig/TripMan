//
//  RouteOverlayView.m
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "RouteOverlayView.h"

@implementation RouteOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (RouteOverlay *)routeOverlay
{
    return (RouteOverlay*)self.overlay;
}

- (id)initWithRouteOverlay:(RouteOverlay *)routeOverlay
{
    self = [super initWithOverlay:routeOverlay];
    if (self) {
    }
    return self;
}

- (void)glRender
{
    RouteOverlay *customOverlay = [self routeOverlay];
    NSString * textureImg = customOverlay.title;
    if ([customOverlay.title isEqualToString:@"yellow"]) {
        textureImg = @"map_yellow.png";
    } else if ([customOverlay.title isEqualToString:@"red"]) {
        textureImg = @"map_red.png";
    } else if ([customOverlay.title isEqualToString:@"green"]) {
        textureImg = @"map_green.png";
    }
    
    GLuint testureID = [self loadStrokeTextureImage:[UIImage imageNamed:textureImg]];
    if (testureID) {
        [self renderTexturedLinesWithPoints:customOverlay.points pointCount:customOverlay.pointCount lineWidth:self.lineWidth textureID:testureID looped:NO];
    } else {
        [self renderLinesWithPoints:customOverlay.points pointCount:customOverlay.pointCount strokeColor:self.strokeColor lineWidth:self.lineWidth looped:NO];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
