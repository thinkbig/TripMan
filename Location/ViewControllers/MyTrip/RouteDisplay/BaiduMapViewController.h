//
//  BaiduMapViewController.h
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "BMapKit.h"

@interface BaiduMapViewController : GViewController <BMKMapViewDelegate>

@property (strong, nonatomic) BMKMapView *      mapView;

@property (nonatomic, strong) TripSummary *     tripSum;

@end
