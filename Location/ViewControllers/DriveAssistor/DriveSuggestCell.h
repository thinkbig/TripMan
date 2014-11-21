//
//  DriveSuggestCell.h
//  Location
//
//  Created by taq on 11/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DriveSuggestCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *toStreet;
@property (weak, nonatomic) IBOutlet UILabel *toLabel;
@property (weak, nonatomic) IBOutlet UILabel *suggestLabel;

@property (weak, nonatomic) IBOutlet UILabel *jamCntLabel;
@property (weak, nonatomic) IBOutlet UILabel *jamDuringLabel;

- (void) updateWithTripSummary:(TripSummary*)sum;

@end


/////////////////////////////////////////////////////////////////////////////////

@interface DriveSuggestPOICell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *destPOILabel;
@property (weak, nonatomic) IBOutlet UILabel *destStreetLabel;
@property (weak, nonatomic) IBOutlet UILabel *estimateDuringLabel;

@end

/////////////////////////////////////////////////////////////////////////////////

@interface SearchPOIHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIView *backgroundMask;

@end
