//
//  TripDetailViewController.h
//  Location
//
//  Created by taq on 10/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GViewController.h"
#import "TripSummary.h"

@interface TripDetailViewController : GViewController

@property (nonatomic, strong) TripSummary *             analyzeSum;

@property (weak, nonatomic) IBOutlet UILabel *          sumLabel;
@property (weak, nonatomic) IBOutlet UILabel *          envLabel;
@property (weak, nonatomic) IBOutlet UILabel *          acceLabel;
@property (weak, nonatomic) IBOutlet UILabel *          turningLabel;

@end
