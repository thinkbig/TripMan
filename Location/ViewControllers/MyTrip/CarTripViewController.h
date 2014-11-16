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

@end
