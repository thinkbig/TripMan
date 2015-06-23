//
//  TSLogger.h
//  tradeshiftHome
//
//  Created by taq on 9/9/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSDefine.h"
#import "GPSFMDBLogger.h"
#import "DDFileLogger.h"
#import "GPSAnalyzerRealTime.h"
#import "GPSAnalyzerOffTime.h"
#import "GPSEventItem.h"
#import "DDLog+CustomTime.h"

typedef NS_ENUM(NSUInteger, eMotionStat) {
    eMotionStatGPSLost = 0,
    eMotionStatStationary = 1,
    eMotionStatWalking = 2,
    eMotionStatRunning = 3,
    eMotionStatDriving = 4
};

@interface GPSLogger : NSObject

@property (nonatomic, strong) GPSFMDBLogger *                   dbLogger;
@property (nonatomic, strong) GPSAnalyzerRealTime *             gpsAnalyzer;
@property (nonatomic, strong) GPSAnalyzerOffTime *              offTimeAnalyzer;
@property (nonatomic, strong) DDFileLogger *                    fileLogger;

+ (instancetype)sharedLogger;

- (void) startLogger;
- (void) stopLogger;

- (void) startFileLogger;
- (void) stopFileLogger;

@end
