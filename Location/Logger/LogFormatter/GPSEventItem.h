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
    
    eGPSEventDriveStart = 1000,
    eGPSEventDriveEnd = 1001
};

@interface GPSEventItem : NSObject

@property (nonatomic, strong) NSDate   *            timestamp;
@property (nonatomic, strong) NSNumber   *          eventType;
@property (nonatomic, strong) NSNumber   *          latitude;
@property (nonatomic, strong) NSNumber   *          longitude;
@property (nonatomic, strong) NSNumber   *          radius;
@property (nonatomic, strong) NSString   *          identifier;
@property (nonatomic, strong) NSString   *          groupName;
@property (nonatomic, strong) NSString   *          message;

- (id)initWithLogMessage:(DDLogMessage *)logMessage;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;

- (BOOL) isValidLocation;

@end
