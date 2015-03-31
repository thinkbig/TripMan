//
//  CTTripReportFacade.h
//  TripMan
//
//  Created by taq on 3/6/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"
#import "TripSummary+Fetcher.h"

@interface CTTripReportFacade : BaseChetuFacade

@property (nonatomic, strong) TripSummary *     sum;
@property (nonatomic) BOOL                      force;

@end
