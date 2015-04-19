//
//  JamZone.h
//  TripMan
//
//  Created by taq on 4/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"
#import "CTBaseLocation.h"

@interface JamZone : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * level;
@property (nonatomic, strong) NSString<Optional> * intro;
@property (nonatomic, strong) CTBaseLocation<Optional> * position;
@property (nonatomic, strong) NSNumber<Optional> * radius;
@property (nonatomic, strong) NSNumber<Optional> * lastRefTime;
@property (nonatomic, strong) NSString<Optional> * direction;

- (CGFloat) headingDegree;

@end
