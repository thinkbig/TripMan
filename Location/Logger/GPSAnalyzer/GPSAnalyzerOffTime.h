//
//  GPSAnalyzerOffTime.h
//  Location
//
//  Created by taq on 9/17/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSTripSummaryAnalyzer.h"
#import "GPSAnalyzeSumItem.h"
#import "GPSFMDBLogger.h"
#import "TripSummary.h"

@interface GPSAnalyzerOffTime : NSObject

@property (nonatomic, strong) GPSFMDBLogger *                   dbLogger;           // must set the fmdbLogger for analyze


- (NSArray*)old_analyzedResultFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit reverseOrder:(BOOL)reverse forceAnalyze:(BOOL)force;

- (void)analyzeAllFinishedTrip:(BOOL)force;
- (void)rollOutOfDateTrip;
- (void)analyzeTripForSum:(TripSummary*)tripSum;

- (NSArray*)tripStartFrom:(NSDate*)fromDate toDate:(NSDate*)toDate forceAnalyze:(BOOL)force;

@end
