//
//  BaiduWeatherFacade.h
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaseBaiduFacade.h"
#import "BaiduWeatherModel.h"

@interface BaiduWeatherFacade : BaseBaiduFacade

@property (nonatomic, strong) NSString *      city;

@end
