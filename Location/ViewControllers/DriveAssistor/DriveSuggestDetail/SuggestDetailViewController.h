//
//  SuggestDetailViewController.h
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import <MapKit/MapKit.h>
#import "A3ParallaxScrollView.h"

@interface SuggestDetailViewController : GViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet A3ParallaxScrollView *rootScrollView;

@property (strong, nonatomic) MKMapView *mapView;

@property (nonatomic, strong) TripSummary *     tripSum;

@end