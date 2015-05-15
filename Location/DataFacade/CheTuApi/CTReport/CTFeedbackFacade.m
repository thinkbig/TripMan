//
//  CTFeedbackFacade.m
//  TripMan
//
//  Created by taq on 5/15/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTFeedbackFacade.h"

@implementation CTFeedbackFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath
{
    return @"user/feedback";
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonType;
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
