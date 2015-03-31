//
//  LocationViewController.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"

@interface LocationViewController : GViewController

@property (weak, nonatomic) IBOutlet UILabel *uidLabel;
@property (weak, nonatomic) IBOutlet UILabel *udidLabel;
@property (weak, nonatomic) IBOutlet UILabel *envLabel;
@property (weak, nonatomic) IBOutlet UILabel *reportLabel;

- (IBAction)forceReport:(id)sender;
- (IBAction)reAnalyzeTrip:(id)sender;

@end
