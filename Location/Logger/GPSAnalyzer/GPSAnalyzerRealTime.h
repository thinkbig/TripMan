//
//  DriveProcessAnalyzer.h
//  Location
//
//  Created by taq on 9/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSDefine.h"
#import "GPSLogItem.h"

#define kMotionCurrentStat              @"kMotionCurrentStat"
#define kMotionIsInTrip                 @"kMotionIsInTrip"

typedef NS_ENUM(NSUInteger, eMoveStat) {
    eMoveStatUnknow = 0,
    eMoveStatLine,
    eMoveStatJump
};

@interface GPSAnalyzerRealTime : DDAbstractLogger <DDLogger>

@property (nonatomic) eMoveStat moveStat;     // 是否是线性移动，还是gps不稳定跳动，根据最近的N（目前为10）个gps点的运动规律

- (void)didLostGPS;

@end
