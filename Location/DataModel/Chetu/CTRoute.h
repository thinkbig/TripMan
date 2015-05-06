//
//  CTRoute.h
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"
#import "CTBaseLocation.h"
#import "GeoTransformer.h"

typedef NS_ENUM(NSUInteger, eStepTraffic) {
    eStepTrafficOk = 0,
    eStepTrafficSlow = 1,
    eStepTrafficVerySlow = 2,
    eStepTrafficDefMax = eStepTrafficVerySlow,
};

@protocol CTJam <NSObject>
@end

@interface CTJam : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * duration;
@property (nonatomic, strong) NSString<Optional> * intro;
@property (nonatomic, strong) CTBaseLocation<Optional> * from;
@property (nonatomic, strong) CTBaseLocation<Optional> * to;
@property (nonatomic, strong) NSNumber<Ignore> * coef;  // 如果就是起点附近的jam，则判断阈值应该是 1.414*2 【（dist*1.414）/duration * 2 】

+ (UIColor*) colorFromTraffic:(eStepTraffic)traffic;
- (eStepTraffic) trafficStat;
- (CLLocationCoordinate2D) centerCoordenate;
- (CGFloat) distanceOfJam;

- (void) calCoefWithStartLoc:(CLLocation*)stLoc;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol CTStep <NSObject>
@end

@interface CTStep : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * distance;
@property (nonatomic, strong) NSNumber<Optional> * duration;
@property (nonatomic, strong) NSNumber<Ignore> * status;
@property (nonatomic, strong) NSString<Optional> * intro;
@property (nonatomic, strong) NSString<Optional> * path;
@property (nonatomic, strong) CTBaseLocation<Optional> * from;
@property (nonatomic, strong) CTBaseLocation<Optional> * to;
@property (nonatomic, strong) NSArray<CTJam, Optional> * jams;

- (eStepTraffic) trafficStat;
- (NSArray*) jamsWithThreshold:(CGFloat)threshold;
- (NSArray*) fullPathOfJam:(CTJam*)jam;
- (NSArray*) pathArray;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 默认都是使用百度坐标，因为这个model是用来地图显示的

@interface CTRoute : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * distance;
@property (nonatomic, strong) NSNumber<Optional> * duration;
@property (nonatomic, strong) CTJam<Optional> * most_jam;    // 表示最长缓行路段，abstract接口用，full接口这部分数据可有可无
@property (nonatomic, strong) CTBaseLocation<Optional> * orig;
@property (nonatomic, strong) CTBaseLocation<Optional> * dest;
@property (nonatomic, strong) NSArray<CTStep, Optional> * steps;
@property (nonatomic, strong) NSString<Optional> * coor_type;

- (void) mergeFromAnother:(CTRoute*)route;
- (eStepTraffic) trafficStat;

- (eCoorType) coorType;
- (void)setCoorType:(eCoorType)coorType;

@end
