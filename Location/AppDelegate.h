//
//  LocationAppDelegate.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationTracker.h"
#import "AFNetworkActivityLogger.h"
#import "BMKGeneralDelegate.h"
#import "BMKMapManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, BMKGeneralDelegate> {
    
    UIBackgroundTaskIdentifier              _bgTask;
    
}

@property (strong, nonatomic) UIWindow *window;
@property LocationTracker * locationTracker;
@property (strong, nonatomic) AFNetworkActivityLogger *afNetworkLogger;
@property (strong, nonatomic) BMKMapManager *  baiduMapManager;
@property (nonatomic) BOOL  isUpdating;

// debug mode
@property (nonatomic) BOOL  forceDriving;

-(void) setupLogger;

@end
