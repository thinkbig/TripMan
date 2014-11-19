//
//  GPSTrafficAnalyzer.h
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPSTrafficAnalyzer : NSObject

+ (NSArray*) trafficJamsInTrip:(TripSummary*)sum withThreshold:(NSTimeInterval)threshold;

@end
