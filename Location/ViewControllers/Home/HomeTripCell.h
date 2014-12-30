//
//  HomeTripCell.h
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXLabel.h"
#import "PICircularProgressView.h"

@interface HomeTripHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *suggestDest;
@property (weak, nonatomic) IBOutlet UILabel *suggestDistFrom;

@end

//////////////////////////////////////////////////////////////////

@interface HomeTripCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *jamImageView;
@property (weak, nonatomic) IBOutlet FXLabel *duringLabel;
@property (weak, nonatomic) IBOutlet FXLabel *jamLabel;
@property (weak, nonatomic) IBOutlet FXLabel *suggestLabel;

@property (weak, nonatomic) IBOutlet UIView *statusContainer;
@property (weak, nonatomic) IBOutlet UIImageView *statusBgImage;
@property (weak, nonatomic) IBOutlet UIView *statusColorView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

//////////////////////////////////////////////////////////////////

@interface HomeHealthCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *todayTripSum;

@property (weak, nonatomic) IBOutlet UILabel *IllegalCount;
@property (weak, nonatomic) IBOutlet UILabel *IllegalPendingCount;

@property (weak, nonatomic) IBOutlet PICircularProgressView *carHealthProgress;
@property (weak, nonatomic) IBOutlet UIImageView *carHealthColorImage;
@property (weak, nonatomic) IBOutlet UILabel *carHeathLabel;

@property (weak, nonatomic) IBOutlet PICircularProgressView *carMaintainProgress;
@property (weak, nonatomic) IBOutlet UIImageView *carMaintainImage;
@property (weak, nonatomic) IBOutlet UILabel *carMaintainLabel;

@end
