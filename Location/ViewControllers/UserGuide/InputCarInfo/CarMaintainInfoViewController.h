//
//  CarMaintainInfoViewController.h
//  TripMan
//
//  Created by taq on 5/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "CarMaintainInfo.h"

@interface CarMaintainInfoViewController : GViewController

@property (weak, nonatomic) IBOutlet UICollectionView *collectView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (nonatomic, strong) CarMaintainInfo *     maintainInfo;

- (IBAction)saveInfo:(id)sender;

@end
