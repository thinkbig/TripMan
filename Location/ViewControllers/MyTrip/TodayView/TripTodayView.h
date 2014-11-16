//
//  TripTodayView.h
//  TripMan
//
//  Created by taq on 11/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TripTodayView : UIView

@property (weak, nonatomic) IBOutlet UIView *firstView;
@property (weak, nonatomic) IBOutlet UILabel *todayDist;
@property (weak, nonatomic) IBOutlet UILabel *tripCount;

@property (weak, nonatomic) IBOutlet UIView *secondView;
@property (weak, nonatomic) IBOutlet UILabel *todayDuring;
@property (weak, nonatomic) IBOutlet UILabel *todayMaxSpeed;

@property (weak, nonatomic) IBOutlet UIView *thirdView;
@property (weak, nonatomic) IBOutlet UILabel *jamDist;
@property (weak, nonatomic) IBOutlet UILabel *jamDuring;
@property (weak, nonatomic) IBOutlet UILabel *trafficLightCnt;
@property (weak, nonatomic) IBOutlet UILabel *trafficLightWaiting;

- (void) updateWithTripsToday:(NSArray*)trips;

@end
