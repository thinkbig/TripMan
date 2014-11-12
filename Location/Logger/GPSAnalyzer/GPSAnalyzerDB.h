//
//  GPSAnalyzerDB.h
//  Location
//
//  Created by taq on 9/16/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSAnalyzeSumItem.h"

@interface GPSAnalyzerDB : NSObject

- (GPSAnalyzeSumItem*)unfinishedTrip;
- (NSArray*)finishedTrip;
- (NSArray*)finishedAndUnAnalyzedTrip;
- (long)beginNewTripAt:(NSDate*)beginDate;
- (void)endTrip:(long)tripId atDate:(NSDate*)endDate;
- (void)updateAnalyzeItem:(GPSAnalyzeSumItem*)item analyzeFinished:(BOOL)isFinished;

- (AnalyzeEnvItem*)analyzedEnvItemForId:(long)tripId;
- (void)updateEnvItem:(AnalyzeEnvItem*)item analyzeFinished:(BOOL)isFinished;

- (AnalyzeDrivingItem*)analyzedDrivingItemForId:(long)tripId;
- (void)updateDrivingItem:(AnalyzeDrivingItem*)item analyzeFinished:(BOOL)isFinished;

- (AnalyzeTurningItem*)analyzedTurningItemForId:(long)tripId;
- (void)updateTurningItem:(AnalyzeTurningItem*)item analyzeFinished:(BOOL)isFinished;

- (GPSAnalyzeSumItem*)lastAnalyzedResult;
- (NSArray*)analyzedResultFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit reverseOrder:(BOOL)reverse;

@end
