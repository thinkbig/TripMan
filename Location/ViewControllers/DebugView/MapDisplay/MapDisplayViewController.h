//
//  MapDisplayViewController.h
//  Location
//
//  Created by taq on 9/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TripSummary.h"

@interface MapDisplayViewController : UIViewController

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) TripSummary *     tripSum;

- (IBAction)switchMap:(UIBarButtonItem*)sender;
- (IBAction)close:(id)sender;

@end
