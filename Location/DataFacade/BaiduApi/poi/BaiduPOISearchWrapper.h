//
//  BaiduPOISearchWrapper.h
//  Location
//
//  Created by taq on 11/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CommonWrapper.h"

@interface BaiduPOISearchWrapper : CommonWrapper <BMKPoiSearchDelegate>

@property (nonatomic, strong) NSString *        searchName;
@property (nonatomic, strong) NSString *        city;

@end
