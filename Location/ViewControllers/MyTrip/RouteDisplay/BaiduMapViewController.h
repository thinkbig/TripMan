//
//  BaiduMapViewController.h
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "BMapBaseViewController.h"

@interface BaiduMapViewController : BMapBaseViewController

@property (nonatomic, strong) TripSummary *     tripSum;
@property (nonatomic, strong) CTRoute *         route;

@end
