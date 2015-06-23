//
//  CTLocReportFacade.h
//  TripMan
//
//  Created by taq on 3/5/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"
#import "ParkingRegion+Fetcher.h"

@interface CTLocReportFacade : BaseChetuFacade

@property (nonatomic, strong) ParkingRegion *       aimRegion;
@property (nonatomic) BOOL                          force;

@end
