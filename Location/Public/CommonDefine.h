//
//  CommonDefine.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#ifndef Location_CommonDefine_h
#define Location_CommonDefine_h

#import "MainTabViewController.h"
#import "AppDelegate.h"

#define COMMON_DEBUG                  1

#define kMaxUserFavLocCnt           3
#define kMostParkingShowCnt         20

#define kNotifyUpgradeComplete        @"kNotifyUpgradeComplete"
#define kNotifyNeedUpdate             @"kNotifyNeedUpdate"


#define DEGREES_TO_RADIANS(x)               (x * M_PI/180.0)
#define UIColorFromRGB(rgbValue)            [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                                green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                                blue:((float)(rgbValue & 0xFF))/255.0 \
                                                alpha:1.0]
#define UIColerFromRGBAlpha(rgbValue)       [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                                green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                                blue:((float)(rgbValue & 0xFF))/255.0 \
                                                alpha:((float)((rgbValue & 0xFF000000) >> 24))/255.0]

#define InstVC(stID, vcID)          [[UIStoryboard storyboardWithName:(stID) bundle:nil] instantiateViewControllerWithIdentifier:(vcID)]
#define InstFirstVC(stID)           [[UIStoryboard storyboardWithName:(stID) bundle:nil] instantiateInitialViewController]

#define MAIN_WINDOW                 ([UIApplication sharedApplication].delegate.window)
#define ROOT_VIEW_CONTROLLER        ((TSTabBarViewController*)(MAIN_WINDOW.rootViewController))
#define MAIN_VIEW_CONTROLLER        (ROOT_VIEW_CONTROLLER.selectedViewController)
#define PRESENT_VIEW_CONTROLLER     ([MAIN_VIEW_CONTROLLER isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)MAIN_VIEW_CONTROLLER).topViewController : MAIN_VIEW_CONTROLLER)
#define LOCATION_TRACKER            (((AppDelegate*)([UIApplication sharedApplication].delegate)).locationTracker)

#define IS_UPDATING                 (((AppDelegate*)([UIApplication sharedApplication].delegate)).isUpdating)
#define IS_WIFI                     (((AppDelegate*)([UIApplication sharedApplication].delegate)).netStat == AFNetworkReachabilityStatusReachableViaWiFi)
#define IS_REACHABLE                (((AppDelegate*)([UIApplication sharedApplication].delegate)).netStat != AFNetworkReachabilityStatusNotReachable)

// directory define
#define DocumentDirectory           [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]


// define common color
#define COLOR_STAT_GREEN            UIColorFromRGB(0x7bce33)
#define COLOR_STAT_YELLOW           UIColorFromRGB(0xffba00)
#define COLOR_STAT_RED              UIColorFromRGB(0xe34b3f)
#define COLOR_STATUS_BLUE           UIColorFromRGB(0x00EBFF)
#define COLOR_UNIT_GRAY             [UIColor colorWithWhite:1.0 alpha:0.54f]

#define COLOR_SEPRATOR_GRAY         UIColorFromRGB(0x393d44)

// defne common font
#define DIGITAL_FONT                @"HelveticaNeue-CondensedBold"
#define DigitalFontSize(sz_)        [UIFont fontWithName:DIGITAL_FONT size:(sz_)]


// system version
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


// debug define
#define IS_FORCE_DRIVING             (((AppDelegate*)([UIApplication sharedApplication].delegate)).forceDriving)

// traffic threshold
#define IGNORE_NAVIGATION_DIST       (1000*100)

#if TARGET_IPHONE_SIMULATOR
#define gDeviceType @"iosSimulator"
#elif TARGET_OS_IPHONE
#define gDeviceType @"iosDevice"
#else
#define gDeviceType @"iosUnknow"
#endif

#endif
