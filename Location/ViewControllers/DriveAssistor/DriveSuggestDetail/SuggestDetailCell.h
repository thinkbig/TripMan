//
//  SuggestDetailCell.h
//  TripMan
//
//  Created by taq on 11/24/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTRoute.h"

@interface SuggestDetailCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *jamStatBgImage;
@property (weak, nonatomic) IBOutlet UILabel *jamStatLabel;
@property (weak, nonatomic) IBOutlet UILabel *jamStatTitle;
@property (weak, nonatomic) IBOutlet UILabel *jamStatSubTitle;
@property (weak, nonatomic) IBOutlet UILabel *jamDurationLabel;

- (void) updateWithJam:(CTJam*)jam;

@end

///////////////////////////////////////////////////////////////

@interface SuggestDetailHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *destLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDistLabel;
@property (weak, nonatomic) IBOutlet UILabel *estimateDuringLabel;

- (void) updateWithRoute:(CTRoute*)route;
- (void) updateWithTrip:(TripSummary*)sum;

@end

///////////////////////////////////////////////////////////////

@interface SuggestPredictCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *jamStatImage;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *predictDurationLabel;

- (void) updateWithStartTime:(NSDate*)stDate andDuration:(NSTimeInterval)duration;

@end


