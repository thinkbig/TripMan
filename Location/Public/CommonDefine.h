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

#define IS_UPDATING                 (((AppDelegate*)([UIApplication sharedApplication].delegate)).isUpdating)

// directory define
#define DocumentDirectory           [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]


// define common color
#define COLOR_STAT_GREEN            UIColorFromRGB(0x7bce33)
#define COLOR_STAT_YELLOW           UIColorFromRGB(0xffba00)
#define COLOR_STAT_RED              UIColorFromRGB(0xe34b3f)
#define COLOR_SEPRATOR_GRAY         UIColorFromRGB(0x393d44)

// debug define
#define IS_FORCE_DRIVING             (((AppDelegate*)([UIApplication sharedApplication].delegate)).forceDriving)

#endif
