//
//  BaseGoogleFacade.m
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseGoogleFacade.h"

@implementation BaseGoogleFacade

- (eRequestType)requestType{
    return eRequestTypeGet;
}

- (NSString *)baseUrl {
    return @"https://roads.googleapis.com/";
}

- (NSString *)getPath{
    return @"v1/%@?key=AIzaSyADYWIGFSnn3DHlJblK0hntz5KQiwbD0hk";
}

@end
