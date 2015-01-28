//
//  GPSAnalyzerOffTime.h
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSTripSummaryAnalyzer.h"
#import "GPSFMDBLogger.h"
#import "TripSummary.h"
#import "WeekSummary.h"
#import "MonthSummary.h"
#import "TripsCoreDataManager.h"

@interface GPSAnalyzerOffTime : NSObject

@property (nonatomic, strong) GPSFMDBLogger *                   dbLogger;           // must set the fmdbLogger for analyze
@property (nonatomic, strong) TripsCoreDataManager *            manager;

- (void)analyzeAllFinishedTrip:(BOOL)force;
- (void)rollOutOfDateTrip;

// analyzer dict key (TurningAnalyzer, AcceleratorAnalyzer)
- (void)analyzeTripForSum:(TripSummary*)tripSum withAnalyzer:(NSDictionary*)anaDict;

- (NSArray*)analyzeTripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate shouldUpdateGlobalInfo:(BOOL)update;

- (void)analyzeDaySum:(DaySummary*)daySum;
- (void)analyzeWeekSum:(WeekSummary*)weekSum;
- (void)analyzeMonthSum:(MonthSummary*)monthSum;

@end
