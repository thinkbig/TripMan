//
//  GPSOffTimeFilter.h
//  Location
//
//  Created by taq on 9/29/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, eTurningStat) {
    eTurningUnknow = 0,
    eTurningStart,
    eTurningLeft,
    eTurningRight,
    eTurningAround,
    eTurningEnd
};

@interface GPSTurningItem : NSObject

@property (nonatomic)   eTurningStat        eStat;
@property (nonatomic)   CGFloat             instSpeed;
@property (nonatomic)   CGFloat             avgSpeed;
@property (nonatomic)   CGFloat             maxSpeed;
@property (nonatomic)   CGFloat             angle;
@property (nonatomic)   CGFloat             distAfterTurning;
@property (nonatomic)   CGFloat             duringAfterTurning;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface GPSOffTimeFilter : NSObject

// 获得关键路径点，返回使用原始gps数据，不做去噪
+ (NSArray*) keyRouteFromGPS:(NSArray*)gpsData autoFilter:(BOOL)filter;
// 把上面函数获得的关键，增加采样间隔，拆成多个steps，等价于上面函数filter=YES
+ (NSArray*) filterWithTurning:(NSArray*)rawRoute;

// 用来去噪，一般repeat为3
+ (NSArray*) smoothGPSData:(NSArray*)gpsData iteratorCnt:(NSInteger)repeat;

// 模拟GPSAnalyzerRealTime中，过滤gps速度的方法，更新速度特别异常的点
+ (void) smoothGpsSpeed:(NSArray*)gpsData;

// 计算拐点的入口
- (void) calGPSDataForTurning:(NSArray*)gpsData smoothFirst:(BOOL)smooth;
- (NSArray*) featurePointIndex;
- (NSArray*) featurePoints;
- (NSArray*) turningParams;

// useful function
+ (CGFloat)checkPointAngle:(CGPoint)pt1 antPt:(CGPoint)pt2 antPt:(CGPoint)pt3;
+ (CGPoint)coor2Point:(CLLocationCoordinate2D)coor;
+ (CGFloat) angleFromPoint:(CGPoint)fromPt toPoint:(CGPoint)toPt;

+ (NSString*) routeToString:(NSArray*)route withTimeStamp:(BOOL)withTime;    // lat,lon|lat,lon
+ (NSArray*) stringToLocationRoute:(NSString*)routeStr; // lat,lon|lat,lon -->  CLLocation

@end
