//
//  Earth2Mars.m
//  Location
//
//  Created by taq on 9/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GeoTransformer.h"

const double x_pi = 3.14159265358979324 * 3000.0 / 180.0;

// 火星GCJ-02 to bd09ll
void bd_encrypt(double gg_lat, double gg_lon, double &bd_lat, double &bd_lon)
{
    double x = gg_lon, y = gg_lat;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) + 0.000003 * cos(x * x_pi);
    bd_lon = z * cos(theta) + 0.0065;
    bd_lat = z * sin(theta) + 0.006;
}

// bd09ll to 火星GCJ-02
void bd_decrypt(double bd_lat, double bd_lon, double &gg_lat, double &gg_lon)
{
    double x = bd_lon - 0.0065, y = bd_lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
    gg_lon = z * cos(theta);
    gg_lat = z * sin(theta);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation GeoTransformer

const double a = 6378245.0;
const double ee = 0.00669342162296594323;

+ (CLLocationCoordinate2D)earth2Mars:(CLLocationCoordinate2D)location {
    if ([[self class] outOfChina:location]) {
        return location;
    }
    double dLat = [[self class] transformLatWithX:location.longitude - 105.0 y:location.latitude - 35.0];
    double dLon = [[self class] transformLonWithX:location.longitude - 105.0 y:location.latitude - 35.0];
    double radLat = location.latitude / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * M_PI);
    
    return CLLocationCoordinate2DMake(location.latitude + dLat, location.longitude + dLon);
}

+ (BOOL)outOfChina:(CLLocationCoordinate2D)location {
    if (location.longitude < 72.004 || location.longitude > 137.8347) {
        return YES;
    }
    if (location.latitude < 0.8293 || location.latitude > 55.8271) {
        return YES;
    }
    return NO;
}

+ (double)transformLatWithX:(double)x y:(double)y {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

+ (double)transformLonWithX:(double)x y:(double)y {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}


+ (CLLocationCoordinate2D)earth2Baidu:(CLLocationCoordinate2D)location
{
    return BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(location, BMK_COORDTYPE_GPS));
}

+ (BMKMapPoint)earth2BaiduProjection:(CLLocationCoordinate2D)location
{
    return BMKMapPointForCoordinate([self earth2Baidu:location]);
}

+ (CLLocationCoordinate2D)baidu2Mars:(CLLocationCoordinate2D)location
{
    double marLat = 0;
    double marLon = 0;
    bd_decrypt(location.latitude, location.longitude, marLat, marLon);
    
    return CLLocationCoordinate2DMake(marLat, marLon);
}

+ (CLLocationCoordinate2D)mars2Baidu:(CLLocationCoordinate2D)location
{
    return BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(location, BMK_COORDTYPE_COMMON));
//    double bdLat = 0;
//    double bdLon = 0;
//    bd_encrypt(location.latitude, location.longitude, bdLat, bdLon);
//    
//    return CLLocationCoordinate2DMake(bdLat, bdLon);
}


@end
