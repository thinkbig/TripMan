//
//  TripTicketView.h
//  Location
//
//  Created by taq on 11/8/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TripSummary.h"

@interface TripTicketView : UIView

// from view content
@property (weak, nonatomic) IBOutlet UILabel *fromPoi;
@property (weak, nonatomic) IBOutlet UILabel *fromStreet;
@property (weak, nonatomic) IBOutlet UILabel *fromDate;

// to view content
@property (weak, nonatomic) IBOutlet UILabel *toPoi;
@property (weak, nonatomic) IBOutlet UILabel *toStreet;
@property (weak, nonatomic) IBOutlet UILabel *toDate;

// sum content
@property (weak, nonatomic) IBOutlet UILabel *distLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *duringLabel;
@property (weak, nonatomic) IBOutlet UILabel *jamDuring;

- (void) updateWithTripSummary:(TripSummary*)sum;

@end
