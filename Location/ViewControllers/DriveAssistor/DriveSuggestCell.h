//
//  DriveSuggestCell.h
//  Location
//
//  Created by taq on 11/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZCollectionTableViewCell.h"
#import "ScrollSegView.h"

@interface SearchPOIHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIView *backgroundMask;
@property (weak, nonatomic) IBOutlet UIImageView *rightIcon;

@end

/////////////////////////////////////////////////////////////////////////////////

@interface DriveSuggestCell : RZCollectionTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *toStreet;
@property (weak, nonatomic) IBOutlet UILabel *toLabel;
@property (weak, nonatomic) IBOutlet UILabel *suggestLabel;

@property (weak, nonatomic) IBOutlet UILabel *jamCntLabel;
@property (weak, nonatomic) IBOutlet UILabel *jamDuringLabel;

- (void) updateWithTripSummary:(TripSummary*)sum;

@end

/////////////////////////////////////////////////////////////////////////////////

@interface SuggestPOICategoryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet ScrollSegView *scrollSeg;

@end

/////////////////////////////////////////////////////////////////////////////////

@interface DriveSuggestPOICell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *destPOILabel;
@property (weak, nonatomic) IBOutlet UILabel *destStreetLabel;
@property (weak, nonatomic) IBOutlet UILabel *estimateDuringLabel;

@end


