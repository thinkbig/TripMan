//
//  HowToCell.h
//  TripMan
//
//  Created by taq on 5/18/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HowToCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mainTitleLabel;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface HowToDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mutableHeightLabel;

+ (CGFloat)heightForCellWithContent:(NSString*)str;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface HowToImageDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mutableHeightLabel;

+ (CGFloat)heightForCellWithContent:(NSString*)str;

@end
