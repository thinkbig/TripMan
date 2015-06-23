//
//  CTFeedbackModel.m
//  TripMan
//
//  Created by taq on 5/15/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTFeedbackModel.h"
#import "BussinessDataProvider.h"

@implementation CTFeedbackModel

- (void) updateLocation
{
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    NSString * city = [[BussinessDataProvider sharedInstance] currentCity];
    
    self.city = city;
    self.loc = [NSString stringWithFormat:@"%.5f,%.5f", curLoc.coordinate.latitude, curLoc.coordinate.longitude];
}

@end
