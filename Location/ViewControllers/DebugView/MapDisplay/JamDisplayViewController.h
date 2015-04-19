//
//  JamDisplayViewController.h
//  TripMan
//
//  Created by taq on 4/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "BMapKit.h"

@interface JamDisplayViewController : GViewController <BMKMapViewDelegate>

@property (strong, nonatomic) BMKMapView *      mapView;

- (IBAction)refresh:(id)sender;

@end
