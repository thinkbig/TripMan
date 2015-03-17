//
//  TripFilter.h
//  TripMan
//
//  Created by taq on 3/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, eDayType) {
    eDayTypeNormal = 0,
    eDayTypeWeekend,
    eDayTypeNationalHoliday,
};

@interface TripFilter : NSObject

+ (eDayType) dayTypeByDate:(NSDate*)date;
+ (NSArray*) filterTrips:(NSArray*)rawArr byTime:(NSDate*)refTime between:(NSTimeInterval)fromMinute toMinute:(NSTimeInterval)toMinute;
+ (NSArray*) filterTrips:(NSArray*)rawArr byDayType:(eDayType)type;

@end
