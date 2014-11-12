//
//  LogFileContentViewController.h
//  Location
//
//  Created by taq on 9/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogFileContentViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *logConentView;

@property (nonatomic, strong) NSString *    logFile;
@property (nonatomic) BOOL                  autoAppend;

- (IBAction)logSwitch:(id)sender;

@end
