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

#define kCarMaintainInfoKey     @"kCarMaintainInfoKey"

@interface CarMaintainInfo () {
    BOOL        _updating;
}

@end

@implementation CarMaintainInfo

- (void)updateDynamicInfo
{
    if (nil == self.userUpdateDate || _updating) {
        return;
    }
    _updating = YES;
    
    if (nil == self.dynamicEndDate) {
        self.dynamicEndDate = [self.userUpdateDate dateAtStartOfDay];
        self.dynamicDist = @(0);
        _updating = NO;
        [self save];
        return;
    }
    
    NSInteger itorCnt = 15;
    NSDate * today = [[NSDate date] dateAtStartOfDay];
    while ([self.dynamicEndDate isEarlierThanDate:today]) {
        DaySummary * daySum = [[AnaDbManager deviceDb] daySummaryByDay:self.dynamicEndDate];
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:daySum];
        
        self.dynamicDist = @([self.dynamicDist floatValue] + [daySum.total_dist floatValue]);
        self.dynamicEndDate = [self.dynamicEndDate dateByAddingDays:1];
        
        if (--itorCnt < 0) {
            break;
        }
    }
    
    [self save];
    if ([self.dynamicEndDate isEarlierThanDate:today]) {
        // not finished， 防止死锁主界面
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateDynamicInfo];
        });
    } else {
        _updating = NO;
    }
}

- (void) load
{
    NSDictionary * modelDict = [[NSUserDefaults standardUserDefaults] objectForKey:kCarMaintainInfoKey];
    [self mergeFromDictionary:modelDict useKeyMapping:NO];
}

- (void) save
{
    NSDictionary * modelDict = [self toDictionary];
    [[NSUserDefaults standardUserDefaults] setObject:modelDict forKey:kCarMaintainInfoKey];
}

@end
