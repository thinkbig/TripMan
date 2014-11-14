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
#import <Parse/Parse.h>
#import <Crashlytics/Crashlytics.h>
#import "NSString+MD5.h"

@implementation AppDelegate

- (NSURL *)applicationDocumentsDirectory
{
    NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"329c7a7f380b233aa478f78c8ccb5edf5ab72278"];
    
    [Parse setApplicationId:@"2Vm0ziBqqos8KflxCetdDffvgq6wg4bj6g3uuWlX" clientKey:@"UZCgfJCFrYqDbEDR1COtoJD0fh51NLQ3bR4HM4lh"];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // iOS 8
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        // iOS 7 or iOS 6
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    self.baiduMapManager = [[BMKMapManager alloc] init];
    BOOL ret = [self.baiduMapManager start:@"dKDmWAUwp4b0BhsxG6IGmiNn" generalDelegate:self];
    if (!ret) {
        DDLogWarn(@"baidu mapmanager start failed!");
    }
    
    // check if need rebuild db
    static NSString * rebuildKey = @"kLocationForceRebuildKey";
    NSString * rebuildVal = @"value_000000000002"; // make sure it is different if this version should rebuild db
    NSString * oldVa = [[NSUserDefaults standardUserDefaults] objectForKey:rebuildKey];
    if (nil == oldVa || ![rebuildVal isEqualToString:oldVa]) {
        [[NSUserDefaults standardUserDefaults] setObject:rebuildVal forKey:rebuildKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // real rebuild db
        [[TripsCoreDataManager sharedManager] dropDb];
        [[BussinessDataProvider sharedInstance] reCreateCoreDataDb];
    }

    [self setupLogger];
    [self applicationDocumentsDirectory];
    
    self.locationTracker = [[LocationTracker alloc] init];
    [self.locationTracker startLocationTracking];
    
    DDLogWarn(@"@@@@@@@@@@@@@ didFinishLaunchingWithOptions @@@@@@@@@@@@@");
    
    [[BussinessDataProvider sharedInstance] updateWeatherToday:nil];
    
    return YES;
}

-(void) setupLogger
{
//    if (nil == self.afNetworkLogger) {
//        self.afNetworkLogger = [[AFNetworkActivityLogger alloc] init];
//        self.afNetworkLogger.level = AFLoggerLevelDebug;
//    }
//    [self.afNetworkLogger startLogging];
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[@"global"];
    [currentInstallation saveInBackground];
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
    [PFPush handlePush:userInfo];
    DDLogWarn(@"$$$$$$$$$$ Did recieve push notifycation = %@", userInfo);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [PFPush handlePush:userInfo];
    if([userInfo[@"aps"][@"content-available"] intValue]== 1) //it's the silent notification
    {
        //bla bla bla put your code here
        DDLogWarn(@"$$$$$$$$$$ Did recieve silent push notifycation = %@", userInfo);
        [self.locationTracker setKeepMonitor];
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
    [DDLog flushLog];
    [[TripsCoreDataManager sharedManager] commit];
    [[NSUserDefaults standardUserDefaults] synchronize];
    DDLogWarn(@"@@@@@@@@@@@@@ applicationWillResignActive @@@@@@@@@@@@@");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogWarn(@"@@@@@@@@@@@@@ applicationDidEnterBackground @@@@@@@@@@@@@");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DDLogWarn(@"@@@@@@@@@@@@@ applicationDidBecomeActive @@@@@@@@@@@@@");
    
    [[GPSLogger sharedLogger].offTimeAnalyzer rollOutOfDateTrip];
    
    [[BussinessDataProvider sharedInstance] updateWeatherToday:nil];
    [[BussinessDataProvider sharedInstance] updateAllRegionInfo:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLogWarn(@"@@@@@@@@@@@@@ applicationWillTerminate @@@@@@@@@@@@@");
    [[NSUserDefaults standardUserDefaults] synchronize];
    [DDLog flushLog];
    [[TripsCoreDataManager sharedManager] commit];
    [self.locationTracker startLocationTracking];
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
