//
//  TripMonthView.h
//  TripMan
//
//  Created by taq on 12/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MonthSummary.h"

@interface TripMonthView : UIView

@property (weak, nonatomic) IBOutlet UIView *viewOne;

@property (weak, nonatomic) IBOutlet UILabel *tolDistLabel;
@property (weak, nonatomic) IBOutlet UILabel *tolDuringLabel;
@property (weak, nonatomic) IBOutlet UILabel *tolCntLabel;

@property (nonatomic, strong) MonthSummary *        monthSum;

- (void) updateMonth;

@end
