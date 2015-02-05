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

// 用来去噪，一般repeat为3
+ (NSArray*) smoothGPSData:(NSArray*)gpsData iteratorCnt:(NSInteger)repeat;

// 计算拐点的入口
- (void) calGPSDataForTurning:(NSArray*)gpsData smoothFirst:(BOOL)smooth;
- (NSArray*) featurePointIndex;
- (NSArray*) featurePoints;
- (NSArray*) turningParams;

// useful function
+ (CGFloat)checkPotinAngle:(CGPoint)pt1 antPt:(CGPoint)pt2 antPt:(CGPoint)pt3;
+ (CGPoint)coor2Point:(CLLocationCoordinate2D)coor;
+ (CGFloat) angleFromPoint:(CGPoint)fromPt toPoint:(CGPoint)toPt;

@end
