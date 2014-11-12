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

+ (CGFloat) dist2FromGPSItem:(GPSLogItem*)fromItem toItem:(GPSLogItem*)toItem;
+ (NSArray*) smoothGPSData:(NSArray*)gpsData iteratorCnt:(NSInteger)repeat;

- (void) calGPSDataForTurning:(NSArray*)gpsData smoothFirst:(BOOL)smooth;
- (NSArray*) featurePointIndex;
- (NSArray*) featurePoints;
- (NSArray*) turningParams;

@end