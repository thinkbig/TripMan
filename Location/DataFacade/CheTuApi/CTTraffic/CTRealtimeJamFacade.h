//
//  CTRealtimeJamFacade.h
//  TripMan
//
//  Created by taq on 4/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"
#import "GeoRectBound.h"

@interface CTRealtimeJamFacade : BaseChetuFacade

@property (nonatomic, strong) GeoRectBound *        geoBound;

@end
