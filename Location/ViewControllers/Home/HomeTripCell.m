//
//  HomeTripCell.m
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "HomeTripCell.h"

@implementation HomeTripHeader

@end

//////////////////////////////////////////////////////////////////

@implementation HomeTripCell

- (void)awakeFromNib
{
    self.statusColorView.layer.cornerRadius = 4;
    
    self.duringLabel.gradientStartPoint = CGPointMake(0.0f, 0.0f);
    self.duringLabel.gradientEndPoint = CGPointMake(1.0f, 1.0f);
    self.duringLabel.gradientColors = @[UIColorFromRGB(0xcef5ff),UIColorFromRGB(0xaaefff)];
    
    self.jamLabel.gradientStartPoint = CGPointMake(0.0f, 0.0f);
    self.jamLabel.gradientEndPoint = CGPointMake(1.0f, 1.0f);
    self.jamLabel.gradientColors = @[UIColorFromRGB(0xe4ffcd),UIColorFromRGB(0xddf2cb)];
    
    self.suggestLabel.gradientStartPoint = CGPointMake(0.0f, 0.0f);
    self.suggestLabel.gradientEndPoint = CGPointMake(1.0f, 1.0f);
    self.suggestLabel.gradientColors = @[UIColorFromRGB(0xe4ffcd),UIColorFromRGB(0xddf2cb)];
}

@end

//////////////////////////////////////////////////////////////////

@implementation HomeHealthCell

- (void)awakeFromNib
{
    // car health chart
    self.carHealthProgress.showText = NO;
    self.carHealthProgress.progress = 0.7;
    
    // car maintain chart
    self.carMaintainProgress.showText = NO;
    self.carMaintainProgress.progress = 0.7;
    self.carMaintainProgress.progressFillColor = COLOR_STAT_RED;
}

@end
