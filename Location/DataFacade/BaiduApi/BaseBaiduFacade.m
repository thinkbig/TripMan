//
//  BaseBaiduFacade.m
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaseBaiduFacade.h"

@implementation BaseBaiduFacade

- (eRequestType)requestType{
    return eRequestTypeGet;
}

- (NSString *)baseUrl {
    return @"http://api.map.baidu.com/";
}

- (NSString *)getPath{
    return @"telematics/v3/%@?output=json&ak=7ZNN5imWdinViWWmBGA3Rlx5";
}

@end
