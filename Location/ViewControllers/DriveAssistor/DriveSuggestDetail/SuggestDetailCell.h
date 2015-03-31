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
