//
//  FAQCell.h
//  TripMan
//
//  Created by taq on 5/18/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FAQCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mainTitleLabel;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface FAQDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mutableHeightLabel;

+ (CGFloat)heightForCellWithContent:(NSString*)str;

@end

