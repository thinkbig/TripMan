//
//  CTBaseLocation.h
//  TripMan
//
//  Created by taq on 3/16/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"

@interface CTBaseLocation : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * lon;
@property (nonatomic, strong) NSNumber<Optional> * lat;

- (CLLocation*) clLocation;

@end
