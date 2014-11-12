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

@interface AppDelegate : UIResponder <UIApplicationDelegate, BMKGeneralDelegate> {
    
    UIBackgroundTaskIdentifier              _bgTask;
    
}

@property (strong, nonatomic) UIWindow *window;
@property LocationTracker * locationTracker;
@property (strong, nonatomic) AFNetworkActivityLogger *afNetworkLogger;
@property (strong, nonatomic) BMKMapManager *  baiduMapManager;

-(void) setupLogger;

@end
