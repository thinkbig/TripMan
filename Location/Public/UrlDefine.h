//
//  UrlDefine.h
//  TripMan
//
//  Created by taq on 2/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#ifndef TripMan_UrlDefine_h
#define TripMan_UrlDefine_h

//#define kChetuBaseUrl       @"http://121.40.193.34:80/"    // prod windows
#define kChetuBaseUrl       @"http://115.29.200.94:80/"      // prod linux1
//#define kChetuBaseUrl       @"http://218.244.139.25/"      // prod linux2

//#define kChetuBaseUrl       @"http://localhost:8000/"     //local
//#define kChetuBaseUrl       @"http://192.168.1.105:8000/"    //local ip


#define ENV_DEVICE_TYPE_IOS     @"1"        // 0=unknow, 1=iOS, 2=Android, 3=OBD
#define ENV_APP_SOURCE          @"0"        // 0=内测推广，1=apple商店，2=googlePlay
#define ENV_COUNTRY_CODE        @"CN"


#define kDeviceToken                @"kADeviceToken"
#define kLocationForceRebuildKey    @"kLocationForceRebuildKey"
#define kLastResignActiveDate       @"kLastResignActiveDate"
#define kDebugEnable                @"kDebugEnable"

#endif
