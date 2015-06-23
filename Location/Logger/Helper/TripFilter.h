//
//  TripFilter.h
//  TripMan
//
//  Created by taq on 3/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, eDayType) {
    eDayTypeAuto = 0,
    eDayTypeNormal,
    eDayTypeWeekend,
    eDayTypeNationalHoliday,
};

@interface TripFilter : NSObject

+ (eDayType) dayTypeByDate:(NSDate*)date;
+ (NSArray*) filterTrips:(NSArray*)rawArr byTime:(NSDate*)refTime between:(NSTimeInterval)fromMinute toMinute:(NSTimeInterval)toMinute;
+ (NSArray*) filterTrips:(NSArray*)rawArr byDayType:(eDayType)type;
+ (NSArray*) filterRegion:(NSArray *)rawRegions byStartRegion:(CLLocation*)loc byDist:(CGFloat)dist onlyRecognized:(BOOL)onlyRecognize;

@end
