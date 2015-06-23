//
//  RouteAnnotation.h
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKPointAnnotation.h"

@interface RouteAnnotation : BMKPointAnnotation

// 0:起点 1：终点 2:节点 3:途经poi点  4：其他车辆位置
@property (nonatomic) int type;

// 100:其他车辆位置   101:其他车辆缓行位置   102:其他车辆拥堵位置         默认表情
// 200:其他车辆位置   201:其他车辆缓行位置   202:其他车辆拥堵位置         女性表情
@property (nonatomic) int subType;

@property (nonatomic) int degree;

@end
