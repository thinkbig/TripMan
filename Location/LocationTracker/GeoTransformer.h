//
//  Earth2Mars.h
//  Location
//
//  Created by taq on 9/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BMapKit.h"

typedef NS_ENUM(NSUInteger, eCoorType) {
    eCoorTypeGps = 0,
    eCoorTypeMars = 1,      // same as google
    eCoorTypeBaidu = 2
};

@interface GeoTransformer : NSObject

+ (CLLocationCoordinate2D)earth2Mars:(CLLocationCoordinate2D)location;

+ (CLLocationCoordinate2D)baidu2Mars:(CLLocationCoordinate2D)location;
+ (CLLocationCoordinate2D)mars2Baidu:(CLLocationCoordinate2D)location;

+ (CLLocationCoordinate2D)earth2Baidu:(CLLocationCoordinate2D)location;
+ (BMKMapPoint)earth2BaiduProjection:(CLLocationCoordinate2D)location;

+ (CLLocationCoordinate2D) baiduCoor:(CLLocationCoordinate2D)coor fromType:(eCoorType)coorType;

@end
