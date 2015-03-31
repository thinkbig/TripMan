//
//  TripFilter.m
//  TripMan
//
//  Created by taq on 3/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripFilter.h"
#import "NSDate+Utilities.h"
#import "ParkingRegion+Fetcher.h"

@implementation TripFilter

+ (eDayType) dayTypeByDate:(NSDate*)date
{
    if ([date isTypicallyWeekend]) {
        return eDayTypeWeekend;
    }
    return  eDayTypeNormal;
}

+ (NSArray*) filterTrips:(NSArray*)rawArr byTime:(NSDate*)refTime between:(NSTimeInterval)fromMinute toMinute:(NSTimeInterval)toMinute
{
    NSMutableArray * backupSums = [NSMutableArray array];
    for (TripSummary * sum in rawArr) {
        NSTimeInterval timetoRef = [sum.start_date minutesFromDateIgnoreDay:refTime];
        if (timetoRef >= fromMinute || timetoRef <= toMinute) {
            [backupSums addObject:sum];
        }
    }
    return backupSums;
}

+ (NSArray*) filterTrips:(NSArray*)rawArr byDayType:(eDayType)type
{
    NSMutableArray * backupSums = [NSMutableArray array];
    for (TripSummary * sum in rawArr) {
        if (eDayTypeNormal == type) {
            if ([sum.start_date isTypicallyWorkday]) {
                [backupSums addObject:sum];
            }
        } else if (eDayTypeWeekend == type) {
            if ([sum.start_date isTypicallyWeekend]) {
                [backupSums addObject:sum];
            }
        }
    }
    return backupSums;
}

+ (NSArray*) filterRegion:(NSArray *)rawRegions byStartRegion:(CLLocation*)loc byDist:(CGFloat)dist
{
    if (nil == loc) {
        return rawRegions;
    }
    NSMutableArray * allRegion = [NSMutableArray arrayWithCapacity:rawRegions.count];
    for (id rawOne in rawRegions) {
        CGFloat realDist = 0;
        if ([rawOne isKindOfClass:[ParkingRegion class]]) {
            ParkingRegion * oneRegion = rawOne;
            realDist = [[oneRegion centerLocation] distanceFromLocation:loc];
        } else if ([rawOne isKindOfClass:[ParkingRegionDetail class]]) {
            ParkingRegion * oneRegion = ((ParkingRegionDetail*)rawOne).coreDataItem;
            realDist = [[oneRegion centerLocation] distanceFromLocation:loc];
        }
        if (realDist > dist) {
            [allRegion addObject:rawOne];
        }
    }
    return allRegion;
}

@end
