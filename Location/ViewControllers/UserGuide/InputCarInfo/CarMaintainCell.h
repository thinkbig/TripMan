//
//  CarMaintainCell.h
//  TripMan
//
//  Created by taq on 5/9/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CarMaintainCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *maintainTitle;
@property (weak, nonatomic) IBOutlet UITextField *maintainContent;
@property (weak, nonatomic) IBOutlet UILabel *maintainUnit;

@end

/////////////////////////////////////////////////////////////////////////////////////

@interface CarMaintainConfirmCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIButton *maintainBtn;

@end
