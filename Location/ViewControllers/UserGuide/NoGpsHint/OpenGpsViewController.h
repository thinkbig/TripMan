//
//  OpenGpsViewController.h
//  TripMan
//
//  Created by taq on 4/5/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"

@interface OpenGpsViewController : GViewController

@property (weak, nonatomic) IBOutlet UIScrollView *ios7HintView;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;

- (IBAction)close:(id)sender;
- (IBAction)openSetting:(id)sender;

@end
