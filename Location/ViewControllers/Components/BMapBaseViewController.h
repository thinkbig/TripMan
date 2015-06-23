//
//  BMapBaseViewController.h
//  TripMan
//
//  Created by taq on 6/12/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "BMapKit.h"
#import "RouteAnnotation.h"
#import "BaiduHelper.h"

@interface BMapBaseViewController : GViewController <BMKMapViewDelegate>

@property (strong, nonatomic) BMKMapView *      mapView;
@property (nonatomic, strong) BaiduHelper *     bdHelper;

@property (nonatomic, strong) NSMutableArray *  fullTurningAnno;

- (NSArray*) filterRouteTurning:(NSArray *)turnsToFilter ofSize:(CGSize)annoSz;

@end
