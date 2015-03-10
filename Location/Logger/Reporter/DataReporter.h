//
//  DataReporter.h
//  TripMan
//
//  Created by taq on 3/2/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, eReportReslut) {
    eReportReslutComplete = 0,
    eReportReslutHalt,
    eReportReslutFail
};

typedef void (^ReportCompleteBlock)(eReportReslut);

@interface DataReporter : NSObject

@property (nonatomic) BOOL  onlyWifiReport;     

+ (instancetype) sharedInst;

- (void) asyncUserDeviceInfo;

- (void)forceAsync;
- (void)aliveAsync;
- (void)asyncFromBackgroundFetch:(ReportCompleteBlock)block;

@end
