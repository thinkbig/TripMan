//
//  CarTripCell.h
//  TripMan
//
//  Created by taq on 12/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPBarsGraphView.h"
#import "CoorViewX.h"

@interface CarTripHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIView *segmentContainer;

- (void) addSegmentView:(UIView*)view;

@end

////////////////////////////////////////////////////////////////////////////////////////

@interface CarTripSliderCell : UICollectionViewCell

- (void) setSliderView:(UIView*)view;

@end

////////////////////////////////////////////////////////////////////////////////////////

@interface CarTripCarouselCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *noResultLabel;

- (void) setCarouselView:(UIView*)view;
- (void) showNoResult:(BOOL)show;

@end

////////////////////////////////////////////////////////////////////////////////////////

@interface WeekSumCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet CoorViewX *xCoorBarView;
@property (weak, nonatomic) IBOutlet MPBarsGraphView *distBarView;
@property (weak, nonatomic) IBOutlet MPBarsGraphView *duringBarView;

@end

