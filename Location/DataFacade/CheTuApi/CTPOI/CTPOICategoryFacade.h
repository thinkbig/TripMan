//
//  CTPOICategoryFacade.h
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CommonFacade.h"
#import "POICategory.h"

@interface CTPOICategoryFacade : CommonFacade

@property (nonatomic, strong) NSString * city;

- (NSArray*) defaultCategorys;

@end
