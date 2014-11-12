//
//  GPSEndTraceAnalyzer.h
//  Location
//
//  Created by taq on 10/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPSEndTraceAnalyzer : NSObject

- (GPSLogItem*) traceGPSEndWithArray:(NSArray*)gpsArray;
- (GPSLogItem*) traceGPSEndWithItem:(GPSLogItem*)gps;
- (void) reset;

@end
