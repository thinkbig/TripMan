//
//  DataDebugPrinter.h
//  Location
//
//  Created by taq on 11/7/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TripSummary.h"

@interface DataDebugPrinter : NSObject

+ (NSString*) printTripSummary:(TripSummary*)sum;

+ (NSString*) printDrivingInfo:(DrivingInfo*)info;
+ (NSString*) printEnvInfo:(EnvInfo*)info;
+ (NSString*) printTurningInfo:(TurningInfo*)info;


+ (NSString*) jsonTripSummary:(TripSummary*)sum;

@end
