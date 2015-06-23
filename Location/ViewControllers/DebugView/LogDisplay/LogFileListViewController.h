//
//  LogFileListViewController.h
//  Location
//
//  Created by taq on 9/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogFileListViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *fileListTable;

- (IBAction)clearAll:(id)sender;

@end
