//
//  BaiduGeocodingWrapper.h
//  Location
//
//  Created by taq on 11/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CommonWrapper.h"

@interface BaiduGeocodingWrapper : CommonWrapper <BMKGeoCodeSearchDelegate>

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;

@end
