//
//  WeatherInfo.h
//  Location
//
//  Created by taq on 11/7/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface WeatherInfo : NSManagedObject

@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSDate * date_day;
@property (nonatomic, retain) NSNumber * hour_period;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSString * moisture;
@property (nonatomic, retain) NSString * pm25;
@property (nonatomic, retain) NSString * temperature;
@property (nonatomic, retain) NSString * weather;
@property (nonatomic, retain) NSString * wind;

@end
