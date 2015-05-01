//
//  TripSimulator.h
//  TripMan
//
//  Created by taq on 4/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TripSimulator;

@protocol TripSimulatorDelegate <NSObject>

- (void) tripSimulator:(TripSimulator*)simulator tripDidStart:(GPSLogItem*)stItem;
- (void) tripSimulator:(TripSimulator*)simulator tripDidEnd:(GPSLogItem*)edItem shouldDrop:(BOOL)ifDrop;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface TripSimulator : NSObject

@property (nonatomic, weak) id<TripSimulatorDelegate>   delegate;
@property (nonatomic, strong) NSArray *                 gpsLogs;

@property (nonatomic, readonly) CGFloat   maxSpeed;

- (void) setExitRegion:(NSDate*)exitDate;

@end
