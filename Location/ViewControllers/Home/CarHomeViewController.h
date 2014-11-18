//
//  CarHomeViewController.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "PICircularProgressView.h"

@interface CarHomeViewController : GViewController

@property (weak, nonatomic) IBOutlet UILabel *suggestDest;
@property (weak, nonatomic) IBOutlet UILabel *suggestDistFrom;

@property (weak, nonatomic) IBOutlet UIView *duringView;
@property (weak, nonatomic) IBOutlet UILabel *duringLabel;
@property (weak, nonatomic) IBOutlet UIView *jamView;
@property (weak, nonatomic) IBOutlet UILabel *jamLabel;
@property (weak, nonatomic) IBOutlet UIView *suggestView;
@property (weak, nonatomic) IBOutlet UILabel *suggestLabel;


@property (weak, nonatomic) IBOutlet PICircularProgressView *carHealthProgress;
@property (weak, nonatomic) IBOutlet UILabel *carHeathLabel;

@property (weak, nonatomic) IBOutlet PICircularProgressView *carMaintainProgress;
@property (weak, nonatomic) IBOutlet UILabel *carMaintainLabel;

@end
