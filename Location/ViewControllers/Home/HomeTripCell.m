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
    self.duringLabel.innerShadowBlur = 2.0f;
    self.duringLabel.innerShadowColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.duringLabel.innerShadowOffset = CGSizeMake(0.0f, 2.0f);
    self.duringLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.duringLabel.shadowBlur = 2;
    self.duringLabel.shadowOffset = CGSizeMake(0, 2);
    
    self.jamLabel.gradientStartPoint = CGPointMake(0.0f, 0.0f);
    self.jamLabel.gradientEndPoint = CGPointMake(1.0f, 1.0f);
    self.jamLabel.gradientColors = @[UIColorFromRGB(0xe4ffcd),UIColorFromRGB(0xddf2cb)];
    self.jamLabel.innerShadowBlur = 2.0f;
    self.jamLabel.innerShadowColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.jamLabel.innerShadowOffset = CGSizeMake(0.0f, 1.0f);
    self.jamLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.jamLabel.shadowBlur = 1;
    self.jamLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.suggestLabel.gradientStartPoint = CGPointMake(0.0f, 0.0f);
    self.suggestLabel.gradientEndPoint = CGPointMake(1.0f, 1.0f);
    self.suggestLabel.gradientColors = @[UIColorFromRGB(0xe4ffcd),UIColorFromRGB(0xddf2cb)];
    self.suggestLabel.innerShadowBlur = 2.0f;
    self.suggestLabel.innerShadowColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.suggestLabel.innerShadowOffset = CGSizeMake(0.0f, 1.0f);
    self.suggestLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.suggestLabel.shadowBlur = 1;
    self.suggestLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.statusContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    self.statusContainer.layer.shadowOffset = CGSizeMake(0, 2);
    self.statusContainer.layer.shadowOpacity = 1.0f;
    self.statusContainer.layer.shadowRadius = 4.0f;
    self.statusContainer.clipsToBounds = NO;
}

@end

//////////////////////////////////////////////////////////////////

@implementation HomeHealthCell

- (void)awakeFromNib
{
    // car health chart
    self.carHealthProgress.progress = 0.7;
    self.carHealthProgress.showShadow = NO;
    
    // car maintain chart
    self.carMaintainProgress.showShadow = NO;
    self.carMaintainProgress.progress = 0.7;
}

@end

//////////////////////////////////////////////////////////////////

@implementation HomeHealthCellNew

- (void)awakeFromNib
{
    // car health chart
    self.carHealthProgress.progress = 0.7;
    self.carHealthProgress.showShadow = NO;
    
    // car maintain chart
    self.carMaintainProgress.showShadow = NO;
    self.carMaintainProgress.progress = 0.7;
}

@end
