//
//  TicketDetailViewController.h
//  TripMan
//
//  Created by taq on 11/25/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "TripSummary.h"

@interface TicketDetailViewController : GViewController <UITextFieldDelegate>

@property (nonatomic, strong) TripSummary *     tripSum;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;

@end
