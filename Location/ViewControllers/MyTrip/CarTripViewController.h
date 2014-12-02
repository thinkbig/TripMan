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

@interface CarTripViewController : GViewController <iCarouselDataSource, iCarouselDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *detailCollection;

@property (strong, nonatomic) DRDynamicSlideShow *slideShow;
@property (strong, nonatomic) iCarousel *carousel;

@end
