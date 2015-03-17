//
//  CTTrafficLightFacade.h
//  TripMan
//
//  Created by taq on 3/16/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"

@interface CTTrafficLightFacade : BaseChetuFacade

@property (nonatomic) CLLocationCoordinate2D        fromCoorBD;       // 百度坐标，因为返回的就是百度坐标
@property (nonatomic) CLLocationCoordinate2D        toCoorBD;

@end
