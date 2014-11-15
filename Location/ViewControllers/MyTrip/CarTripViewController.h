//
//  CarTripViewController.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "iCarousel.h"
#import "DRDynamicSlideShow.h"

@interface CarTripViewController : GViewController

@property (weak, nonatomic) IBOutlet UIView *segmentView;

@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIView *noResultView;


@property (weak, nonatomic) IBOutlet DRDynamicSlideShow *slideShow;

@property (weak, nonatomic) IBOutlet UIView *todayView;

@property (weak, nonatomic) IBOutlet UILabel *todayDist;
@property (weak, nonatomic) IBOutlet UILabel *tripCount;

@property (weak, nonatomic) IBOutlet UILabel *todayDuring;
@property (weak, nonatomic) IBOutlet UILabel *todayMaxSpeed;

@property (weak, nonatomic) IBOutlet UILabel *jamDist;
@property (weak, nonatomic) IBOutlet UILabel *jamDuring;
@property (weak, nonatomic) IBOutlet UILabel *trafficLightCnt;
@property (weak, nonatomic) IBOutlet UILabel *trafficLightWaiting;

@end
