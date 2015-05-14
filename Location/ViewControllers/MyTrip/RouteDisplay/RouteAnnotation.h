//
//  RouteAnnotation.h
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKPointAnnotation.h"

@interface RouteAnnotation : BMKPointAnnotation

@property (nonatomic) int type;         // 0:起点 1：终点 2:节点 3:途经poi点 4:其他车辆（拥堵）位置
@property (nonatomic) int degree;

@end
