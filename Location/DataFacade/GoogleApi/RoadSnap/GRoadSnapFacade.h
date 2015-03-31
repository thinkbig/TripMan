//
//  GRoadSnapFacade.h
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseGoogleFacade.h"
#import "GPlaceModel.h"

@interface GRoadSnapFacade : BaseGoogleFacade

@property (nonatomic, strong) NSArray *     snapPath;
@property (nonatomic) BOOL                  interpolate;

@end
