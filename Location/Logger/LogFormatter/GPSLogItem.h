//
//  GPSLogItem.h
//  Location
//
//  Created by taq on 9/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "FMDB.h"
#import "GPSEventItem.h"
#import "ParkingRegion.h"

@interface GPSLogItem : NSObject

@property (nonatomic) BOOL                          isValid;
@property (nonatomic) BOOL                          isKeyPoint;     // 是否是 关键拐点，或者是拥堵起始点

@property (nonatomic, strong) NSDate   *            timestamp;
@property (nonatomic, strong) NSNumber   *          latitude;
@property (nonatomic, strong) NSNumber   *          longitude;
@property (nonatomic, strong) NSNumber   *          altitude;
@property (nonatomic, strong) NSNumber   *          horizontalAccuracy;
@property (nonatomic, strong) NSNumber   *          verticalAccuracy;
@property (nonatomic, strong) NSNumber   *          course;
@property (nonatomic, strong) NSNumber   *          speed;
@property (nonatomic, strong) NSNumber   *          accelerationX;
@property (nonatomic, strong) NSNumber   *          accelerationY;
@property (nonatomic, strong) NSNumber   *          accelerationZ;

// helper property
@property (nonatomic) float angle;      // 和上一个点的矢量方向
@property (nonatomic) float angleDiff;  // 和上一个点矢量方向的差

- (id)initWithLogMessage:(DDLogMessage *)logMessage;
- (id)initWithDBResultSet:(FMResultSet*)resultSet;
- (id)initWithEventItem:(GPSEventItem*)event;
- (id)initWithParkingRegion:(ParkingRegion*)region;

- (CLLocation*) location;
- (CLLocationCoordinate2D) coordinate;
- (double) safeSpeed;
- (CLLocationDistance) distanceFrom:(GPSLogItem*)item;
- (CLLocationDistance) distanceFromDict:(NSDictionary*)dict;

- (NSArray*) toArray;

@end
