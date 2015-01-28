//
//  GPSEventItem.h
//  Location
//
//  Created by taq on 10/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

typedef NS_ENUM(NSInteger, eGPSEvent) {
    eGPSEventDefault = 0,
    
    eGPSEventStartGPS = 100,
    eGPSEventStopGPS,
    eGPSEventGPSLost,
    eGPSEventGPSFail,
    eGPSEventGPSDeny,
    
    eGPSEventMonitorRegion = 200,
    eGPSEventExitRegion,
    eGPSEventEnterRegion,
    eGPSEventMonitorFail,
    
    eGPSEventLogin = 300,
    eGPSEventLogout = 301,
    eGPSEventSwitchCar = 302,
    
    eGPSEventDriveStart = 1000,
    eGPSEventDriveEnd = 1001,
    eGPSEventDriveIgnore = 1002          // ignore this trip, replacement of eGPSEventDriveEnd if we find it is a mistake of eGPSEventDriveStart some time before
};

@interface GPSEventItem : NSObject

@property (nonatomic, strong) NSDate   *            timestamp;
@property (nonatomic, strong) NSNumber   *          eventType;
@property (nonatomic, strong) NSNumber   *          latitude;
@property (nonatomic, strong) NSNumber   *          longitude;
@property (nonatomic, strong) NSNumber   *          radius;
@property (nonatomic, strong) NSString   *          identifier;     // uid for login event
@property (nonatomic, strong) NSString   *          groupName;      // car number for swich event
@property (nonatomic, strong) NSString   *          message;

- (id)initWithLogMessage:(DDLogMessage *)logMessage;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;

- (BOOL) isValidLocation;

@end
