//
//  DriveSuggestCell.h
//  Location
//
//  Created by taq on 11/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DriveSuggestCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *fromLabel;
@property (weak, nonatomic) IBOutlet UILabel *toLabel;
@property (weak, nonatomic) IBOutlet UILabel *suggestLabel;

@property (weak, nonatomic) IBOutlet UILabel *jamCntLabel;
@property (weak, nonatomic) IBOutlet UILabel *jamDuringLabel;

- (void) updateWithTripSummary:(TripSummary*)sum;

@end
