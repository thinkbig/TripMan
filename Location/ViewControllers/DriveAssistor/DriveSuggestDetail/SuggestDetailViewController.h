//
//  SuggestDetailViewController.h
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "BMapKit.h"
#import "A3ParallaxScrollView.h"
#import "CTRoute.h"

@interface SuggestDetailViewController : GViewController <BMKMapViewDelegate>

@property (weak, nonatomic) IBOutlet A3ParallaxScrollView *rootScrollView;

@property (strong, nonatomic) BMKMapView *mapView;

@property (nonatomic, strong) TripSummary *     tripSum;
@property (nonatomic, strong) CTRoute *         route;
@property (nonatomic, strong) NSArray *         waypts;

- (IBAction)switchRoute:(id)sender;

@end
