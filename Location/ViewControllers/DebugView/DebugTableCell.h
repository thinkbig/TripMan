//
//  DebugTableCell.h
//  TripMan
//
//  Created by taq on 4/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DebugTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;

@end
