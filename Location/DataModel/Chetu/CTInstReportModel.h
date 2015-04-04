//
//  CTInstReportModel.h
//  TripMan
//
//  Created by taq on 4/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"

@interface CTInstReportModel : JSONModel

@property (nonatomic, strong) NSString<Optional> * jam_id;
@property (nonatomic, strong) NSString<Optional> * ignore;      // 如果发现这个不是拥堵，设置这个标记为忽略，并上报

@property (nonatomic, strong) NSNumber<Optional> * st_date;
@property (nonatomic, strong) NSNumber<Optional> * ed_date;

@property (nonatomic, strong) NSNumber<Optional> * st_lat;
@property (nonatomic, strong) NSNumber<Optional> * st_lon;
@property (nonatomic, strong) NSNumber<Optional> * ed_lat;
@property (nonatomic, strong) NSNumber<Optional> * ed_lon;

@property (nonatomic, strong) NSNumber<Optional> * user_lat;
@property (nonatomic, strong) NSNumber<Optional> * user_lon;

@property (nonatomic, strong) NSString<Optional> * waypoints;

- (CLLocationCoordinate2D) userCoordinate;

- (void) updateWithStartItem:(GPSLogItem*)item;
- (void) updateWithUserLocation:(CLLocationCoordinate2D)locCoor;
- (void) updateWithEndItem:(GPSLogItem*)item;

@end
