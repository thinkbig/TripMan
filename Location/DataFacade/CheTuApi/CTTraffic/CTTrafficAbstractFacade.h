//
//  CTTrafficAbstractFacade.h
//  TripMan
//
//  Created by taq on 2/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"

@interface CTTrafficAbstractFacade : BaseChetuFacade

@property (nonatomic) CLLocationCoordinate2D        fromCoorBaidu;
@property (nonatomic) CLLocationCoordinate2D        toCoorBaidu;

@property (nonatomic, strong) NSString *            fromParkingId;
@property (nonatomic, strong) NSString *            toParkingId;

@end
