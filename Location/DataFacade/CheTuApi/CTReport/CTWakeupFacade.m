//
//  CTWakeupFacade.m
//  TripMan
//
//  Created by taq on 3/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTWakeupFacade.h"

@implementation CTWakeupFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath {
    return @"user/wakeup";
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonType;
}

- (NSDictionary*)requestParam
{
    NSDictionary * plistDict = [[NSBundle mainBundle] infoDictionary];
    NSString * udid = [[GToolUtil sharedInstance] deviceId];
    NSString * uid = [[GToolUtil sharedInstance] userId];
    NSString * deviceInfo = [NSString stringWithFormat:@"name=%@,model=%@", [UIDevice currentDevice].name, gDeviceType];
    NSString* deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceToken];
    NSMutableDictionary * param = [NSMutableDictionary dictionaryWithDictionary:@{@"udid": udid,
                                                                                  @"verify_key": [GToolUtil verifyKey:udid],
                                                                                  @"device_type": ENV_DEVICE_TYPE_IOS,
                                                                                  @"source": ENV_APP_SOURCE,
                                                                                  @"country_code": ENV_COUNTRY_CODE,
                                                                                  @"version": plistDict[@"CFBundleVersion"],
                                                                                  @"device_info": deviceInfo}];
    if (uid) param[@"user_id"] = uid;
    if (deviceToken) param[@"device_token"] = deviceToken;
    
    return param;
}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
