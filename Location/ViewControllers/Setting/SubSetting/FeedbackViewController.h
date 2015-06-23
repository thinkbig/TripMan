//
//  FeedbackViewController.h
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "TSPlaceHolderTextView.h"

@interface FeedbackViewController : GViewController

@property (weak, nonatomic) IBOutlet UIScrollView *contentScroll;
@property (weak, nonatomic) IBOutlet UITextField *contactField;
@property (weak, nonatomic) IBOutlet TSPlaceHolderTextView *feedbackField;

- (IBAction)sendFeedback:(id)sender;

@end
