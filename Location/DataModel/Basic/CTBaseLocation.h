//
//  CTBaseLocation.h
//  TripMan
//
//  Created by taq on 3/16/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"
#import "GPSLogItem.h"

@protocol CTBaseLocation <NSObject>

@end

@interface CTBaseLocation : JSONModel

@property (nonatomic, strong) NSDate<Optional> *   ts;
@property (nonatomic, strong) NSNumber<Optional> * lon;
@property (nonatomic, strong) NSNumber<Optional> * lat;
@property (nonatomic, strong) NSNumber<Optional> * accu;    // 如果是用户gps，则这个表示精度。负数表示可信数据，比如地图数据
@property (nonatomic, strong) NSString<Optional> * name;
@property (nonatomic, strong) NSString<Optional> * street;
@property (nonatomic, strong) NSString<Optional> * city;

- (id)initWithLogItem:(GPSLogItem*)item;

- (CLLocationCoordinate2D) coordinate;
- (CLLocation*) clLocation;

- (void) updateWithCoordinate:(CLLocationCoordinate2D)coor;
- (BOOL) updateWithCoordinateStr:(NSString*)coorStr;

- (CGFloat) distanceFrom:(CTBaseLocation*)loc;
- (CGFloat) distanceFromLoc:(CLLocation*)loc;

@end
