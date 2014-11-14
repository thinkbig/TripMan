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

@interface GPSAnalyzerOffTime : NSObject

@property (nonatomic, strong) GPSFMDBLogger *                   dbLogger;           // must set the fmdbLogger for analyze

- (void)analyzeAllFinishedTrip:(BOOL)force;
- (void)rollOutOfDateTrip;

// analyzer dict key (TurningAnalyzer, AcceleratorAnalyzer)
- (void)analyzeTripForSum:(TripSummary*)tripSum withAnalyzer:(NSDictionary*)anaDict;

- (NSArray*)analyzeTripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate;

@end
