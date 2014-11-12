//
//  BaiduReverseGeocodingWrapper.h
//  Location
//
//  Created by taq on 11/6/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CommonWrapper.h"

@interface BaiduReverseGeocodingWrapper : CommonWrapper <BMKGeoCodeSearchDelegate>

@property (nonatomic) CLLocationCoordinate2D        coordinate;

@end
