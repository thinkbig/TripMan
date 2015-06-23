//
//  BaiduRoadMarkFacade.h
//  TripMan
//
//  Created by taq on 11/13/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaseBaiduFacade.h"
#import "BaiduMarkModel.h"

@interface BaiduRoadMarkFacade : BaseBaiduFacade

@property (nonatomic) CLLocationCoordinate2D        fromCoor;
@property (nonatomic) CLLocationCoordinate2D        toCoor;

@end
