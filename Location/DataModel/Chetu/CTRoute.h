//
//  CTRoute.h
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"
#import "CTBaseLocation.h"

typedef NS_ENUM(NSUInteger, eStepTraffic) {
    eStepTrafficOk = 0,
    eStepTrafficSlow = 1,
    eStepTrafficVerySlow = 2,
    eStepTrafficDefMax = eStepTrafficVerySlow,
};

@protocol CTStep <NSObject>
@end

@interface CTStep : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * distance;
@property (nonatomic, strong) NSNumber<Optional> * duration;
@property (nonatomic, strong) NSNumber<Optional> * status;
@property (nonatomic, strong) NSString<Optional> * intro;
@property (nonatomic, strong) NSString<Optional> * path;
@property (nonatomic, strong) CTBaseLocation<Optional> * from;
@property (nonatomic, strong) CTBaseLocation<Optional> * to;

- (eStepTraffic) trafficStat;
- (NSArray*) pathArray;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 默认都是使用百度坐标，因为这个model是用来地图显示的

@interface CTRoute : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * distance;
@property (nonatomic, strong) NSNumber<Optional> * duration;
@property (nonatomic, strong) NSNumber<Optional> * status;
@property (nonatomic, strong) CTBaseLocation<Optional> * orig;
@property (nonatomic, strong) CTBaseLocation<Optional> * dest;
@property (nonatomic, strong) NSArray<CTStep, Optional> * steps;

- (void) updateWithDestRegion:(ParkingRegion*)region fromCurrentLocation:(CLLocation*)curLoc;
- (void) updateWithDestCoor:(CLLocationCoordinate2D)coor andDestName:(NSString*)destName fromCurrentLocation:(CLLocation*)curLoc;

- (void) mergeFromAnother:(CTRoute*)route;
- (eStepTraffic) trafficStat;

@end
