//
//  POICategory.h
//  TripMan
//
//  Created by taq on 12/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "JSONModel.h"

@interface POICategory : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * poi_type;
@property (nonatomic, strong) NSString<Optional> * disp_name;

@end

/////////////////////////////////////////////////////////////////////////////

@interface POICategoryDetail : JSONModel

@property (nonatomic, strong) NSString<Optional> * icon;
@property (nonatomic, strong) NSString<Optional> * name;
@property (nonatomic, strong) NSString<Optional> * address;
@property (nonatomic, strong) NSNumber<Optional> * during;
@property (nonatomic, strong) NSNumber<Optional> * status;

@end
