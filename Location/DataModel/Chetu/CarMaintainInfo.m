//
//  CarMaintainInfo.m
//  TripMan
//
//  Created by taq on 5/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CarMaintainInfo.h"
#import "NSDate+Utilities.h"
#import "TSCache.h"

@interface CarMaintainInfo ()

@property (nonatomic, strong) NSString<Ignore> *        filePath;

@end

@implementation CarMaintainInfo

- (NSInteger) totalDist {
    return [self.userTotalDist integerValue] + [self.dynamicDist integerValue];
}

- (NSInteger) distSinceLastMaintain {
    return [self totalDist] - [self.userLastMaintainDist integerValue];
}

- (void)setUserUpdateDate:(NSDate *)userUpdateDate {
    _userUpdateDate = userUpdateDate;
    self.dynamicEndDate = nil;
    self.dynamicDist = @(0);
}

- (void)updateDynamicInfo
{
    if (nil == self.userUpdateDate) {
        return;
    }
    
    if (nil == self.dynamicEndDate) {
        self.dynamicEndDate = [self.userUpdateDate dateAtStartOfDay];
        self.dynamicDist = @(0);
    }
    
    NSDate * today = [[NSDate date] dateAtStartOfDay];
    while ([self.dynamicEndDate isEarlierThanDate:today]) {
        DaySummary * daySum = [[AnaDbManager deviceDb] daySummaryByDay:self.dynamicEndDate];
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:daySum];
        
        self.dynamicDist = @([self.dynamicDist floatValue] + [daySum.total_dist floatValue]/1000.0);
        self.dynamicEndDate = [self.dynamicEndDate dateByAddingDays:1];
    }
}

- (NSNumber<Optional> *)thresMaintainDist {
    if (_thresMaintainDist) {
        return _thresMaintainDist;
    }
    return @(5000);
}

- (NSString*) filePath
{
    if (nil == _filePath) {
        NSString * ducumentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _filePath = [ducumentDirectory stringByAppendingPathComponent:@"CarMaintainInfo.plist"];
    }
    return _filePath;
}

- (void) load
{
    NSDictionary * modelDict = [NSDictionary dictionaryWithContentsOfFile:self.filePath];
    [self mergeFromDictionary:modelDict useKeyMapping:NO];
}

- (void) save
{
    [self updateDynamicInfo];
    NSDictionary * modelDict = [self toDictionary];
    [modelDict writeToFile:self.filePath atomically:YES];
}

@end
