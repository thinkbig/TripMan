//
//  CarTripViewController.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "iCarousel.h"

@interface CarTripViewController : GViewController

@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIView *noResultView;

@property (weak, nonatomic) IBOutlet UIView *todayView;
@property (weak, nonatomic) IBOutlet UILabel *todayLabel;
@property (weak, nonatomic) IBOutlet UILabel *todayDist;
@property (weak, nonatomic) IBOutlet UILabel *todayDuring;
@property (weak, nonatomic) IBOutlet UILabel *todayMaxSpeed;

@end
