//
//  LocationAppDelegate.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "AppDelegate.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "GPSLogger.h"
//#import <Parse/Parse.h>
#import <Crashlytics/Crashlytics.h>
#import "UserWrapper.h"
#import "NSString+MD5.h"
#import "DataReporter.h"

static NSString * rebuildVal = @"value_0000000000005"; // make sure it is different if this version should rebuild db

@implementation AppDelegate

- (NSURL *)applicationDocumentsDirectory
{
    NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"329c7a7f380b233aa478f78c8ccb5edf5ab72278"];
    
    self.netStat = AFNetworkReachabilityStatusUnknown;
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        self.netStat = status;
    }];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //[Parse setApplicationId:@"VCNBKwPC8YeWAmKzqkviTZe1Z98hOaTfRG1J2S1b" clientKey:@"HGa0WMdH6of49dlPIQjQC5UZZvweIVl6DjK0KUhc"];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // iOS 8
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
        [[UINavigationBar appearance] setTranslucent:NO];
    } else {
        // iOS 7 or iOS 6
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x0C2160)];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                                           NSFontAttributeName: [UIFont boldSystemFontOfSize:20],
                                                           }];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[BussinessDataProvider sharedInstance] registerLoginLisener];
    
    self.baiduMapManager = [[BMKMapManager alloc] init];
    
    // check if need rebuild db
    NSString * oldVal = [[NSUserDefaults standardUserDefaults] objectForKey:kLocationForceRebuildKey];
    if (oldVal && ![rebuildVal isEqualToString:oldVal])
    {
        IS_UPDATING = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateComplete) name:kNotifyUpgradeComplete object:nil];

        // real rebuild db
        [[AnaDbManager sharedInst] dropDbAll];
        [[BussinessDataProvider sharedInstance] reCreateCoreDataDb];
    } else {
        [self updateComplete];
    }
    
    DDLogWarn(@"@@@@@@@@@@@@@ didFinishLaunchingWithOptions @@@@@@@@@@@@@");
    
    return YES;
}

- (void) updateComplete
{
    NSLog(@"updateComplete");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSUserDefaults standardUserDefaults] setObject:rebuildVal forKey:kLocationForceRebuildKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    IS_UPDATING = NO;
    
    BOOL ret = [self.baiduMapManager start:@"9NBl87wrIw0YYwwsp9SaGqNy" generalDelegate:self];
    if (!ret) {
        DDLogWarn(@"baidu mapmanager start failed!");
    }
    
    [self setupLogger];
    [self applicationDocumentsDirectory];
    
    if (nil == self.locationTracker) {
        self.locationTracker = [[LocationTracker alloc] init];
    }
    [self.locationTracker updateCurrentLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyNeedUpdate object:nil];
}

- (void) setupLogger
{
    if ([GToolUtil isEnableDebug]) {
        if (nil == self.afNetworkLogger) {
            self.afNetworkLogger = [[AFNetworkActivityLogger alloc] init];
            self.afNetworkLogger.level = AFLoggerLevelDebug;
        }
        [self.afNetworkLogger startLogging];
        
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

//For interactive notification only
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString * dt = [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[NSUserDefaults standardUserDefaults] setValue:dt forKey:kDeviceToken];
    [[DataReporter sharedInst] asyncUserDeviceInfo];
    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    [currentInstallation setDeviceTokenFromData:deviceToken];
//    currentInstallation.channels = @[@"global"];
//    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        DDLogWarn(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        DDLogWarn(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //[PFPush handlePush:userInfo];
    DDLogWarn(@"$$$$$$$$$$ Did recieve push notifycation = %@", userInfo);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    //[PFPush handlePush:userInfo];
    if([userInfo[@"aps"][@"content-available"] intValue]== 1) //it's the silent notification
    {
        //bla bla bla put your code here
        DDLogWarn(@"$$$$$$$$$$ Did recieve silent push notifycation = %@", userInfo);
        if (DEBUG_MODE) {
            self.forceDriving = YES;
        }
        [self.locationTracker startLocationTracking];
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    else
    {
        DDLogWarn(@"$$$$$$$$$$ Did recieve normal notifycation = %@", userInfo);
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    if (!IS_UPDATING) {
        [DDLog flushLog];
        [[AnaDbManager deviceDb] commit];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastResignActiveDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
    DDLogWarn(@"@@@@@@@@@@@@@ applicationWillResignActive @@@@@@@@@@@@@");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogWarn(@"@@@@@@@@@@@@@ applicationDidEnterBackground @@@@@@@@@@@@@");
    UIApplication * app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    if (!IS_UPDATING) {
        [self.locationTracker updateCurrentLocation];
    }
    
    if (nil == self.bgHintVC) {
        self.bgHintVC = [[BGHintViewController alloc] initWithNibName:@"BGHintViewController" bundle:nil];
        self.bgHintVC.view.frame = self.window.bounds;
        self.bgHintVC.bgContent.frame = self.bgHintVC.view.bounds;
    }
    [self.window addSubview:self.bgHintVC.view];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.bgHintVC.view removeFromSuperview];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DDLogWarn(@"@@@@@@@@@@@@@ applicationDidBecomeActive @@@@@@@@@@@@@");
    
    [[DataReporter sharedInst] asyncUserDeviceInfo];
    
    if (!IS_UPDATING) {
        [[GPSLogger sharedLogger].offTimeAnalyzer rollOutOfDateTrip];
        
        BussinessDataProvider * provider = [BussinessDataProvider sharedInstance];
        [provider updateDeviceHistory];
        [provider updateCurrentCity:nil forceUpdate:NO];
        [provider updateAllRegionInfo:NO];
        
        [[DataReporter sharedInst] aliveAsync];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLogWarn(@"@@@@@@@@@@@@@ applicationWillTerminate @@@@@@@@@@@@@");
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (!IS_UPDATING) {
        [DDLog flushLog];
        [[AnaDbManager deviceDb] commit];
        [self.locationTracker updateCurrentLocation];
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogWarn(@"############## Background fetch started... #############");
    
    //---do background fetch here---
    // You have up to 30 seconds to perform the fetch
    
    if (!IS_UPDATING) {
        [[DataReporter sharedInst] asyncFromBackgroundFetch:^(eReportReslut result) {
            DDLogWarn(@"############## Background fetch result (%ld) ... #############", (unsigned long)result);
            if (eReportReslutComplete == result) {
                completionHandler(UIBackgroundFetchResultNewData);
            } else {
                completionHandler(UIBackgroundFetchResultFailed);
            }
        }];
        if (IS_WIFI) {
            [[BussinessDataProvider sharedInstance] updateCurrentCity:nil forceUpdate:NO];
            [[BussinessDataProvider sharedInstance] updateAllRegionInfo:NO];
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if([url.scheme isEqualToString:@"carmap"]) {
        [self internalParseURL:url application:application];
    }
    
    return YES;
}

- (void)internalParseURL:(NSURL *)url application:(UIApplication *)application {

}


#pragma mark - BMKGeneralDelegate

- (void)onGetNetworkState:(int)iError
{
    if (0 == iError) {
        DDLogWarn(@"联网成功");
    } else {
        DDLogWarn(@"onGetNetworkState %d",iError);
    }
}

- (void)onGetPermissionState:(int)iError
{
    if (0 == iError) {
        DDLogWarn(@"授权成功");
    } else {
        DDLogWarn(@"onGetPermissionState %d",iError);
    }
}

@end
