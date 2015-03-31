//
//  CTTrafficFullFacade.h
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"

@interface CTTrafficFullFacade : BaseChetuFacade

@property (nonatomic) CLLocationCoordinate2D        fromCoorBaidu;
@property (nonatomic) CLLocationCoordinate2D        toCoorBaidu;
@property (nonatomic, strong) NSArray *             wayPtsBaidu;

- (void) updateWithGpsWayPts:(NSArray*)waypts; 

@end
