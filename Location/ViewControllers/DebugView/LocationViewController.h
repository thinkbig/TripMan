//
//  LocationViewController.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *contentTable;

- (IBAction)refresh:(id)sender;
- (IBAction)closeDebug:(id)sender;

@end
