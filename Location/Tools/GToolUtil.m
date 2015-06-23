//
//  GToolUtil.m
//  TripMan
//
//  Created by taq on 12/2/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GToolUtil.h"
#import "JGProgressHUD.h"
#import "JGProgressHUDFadeZoomAnimation.h"
#import "JGProgressHUDPieIndicatorView.h"
#import "JGProgressHUDSuccessIndicatorView.h"
#import "FXKeychain.h"
#import "NSString+ShiftEncode.h"
#import "NSString+MD5.h"

@interface GToolUtil ()

@property (nonatomic, strong) JGProgressHUD *       sharedPitHUD;

@end

@implementation GToolUtil

static GToolUtil * _sharedUtil = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedUtil = [[GToolUtil alloc] init];
    });
    return _sharedUtil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        static NSString * kTripManDeviceIdKey = @"kTripManDeviceIdKey";
        _deviceId = [[FXKeychain defaultKeychain] objectForKey:kTripManDeviceIdKey];
        if (nil == _deviceId) {
            // FXKeychain may have bug, check user default
            _deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:kTripManDeviceIdKey];
            if (nil == _deviceId) {
                _deviceId = [UIDevice currentDevice].identifierForVendor.UUIDString;
                if (nil == _deviceId) {
                    _deviceId = [GToolUtil createUUID];
                }
                [[NSUserDefaults standardUserDefaults] setObject:_deviceId forKey:kTripManDeviceIdKey];
                [[FXKeychain defaultKeychain] setObject:_deviceId forKey:kTripManDeviceIdKey];
            }
        }
    }
    return self;
}

+ (NSString*)msgWithErr:(NSError*)err andDefaultMsg:(NSString*)msg
{
    if (eNetworkError == err.code) {
        return @"网络不太给力哦";
    }
    return msg;
}

+ (void)showToast:(NSString*)msg
{
    JGProgressHUD *HUD = [[JGProgressHUD alloc] initWithStyle:JGProgressHUDStyleDark];
    HUD.interactionType = JGProgressHUDInteractionTypeBlockTouchesOnHUDView;
    HUD.animation = [JGProgressHUDFadeZoomAnimation animation];
    HUD.HUDView.layer.shadowColor = [UIColor blackColor].CGColor;
    HUD.HUDView.layer.shadowOffset = CGSizeZero;
    HUD.HUDView.layer.shadowOpacity = 0.4f;
    HUD.HUDView.layer.shadowRadius = 8.0f;
    
    HUD.indicatorView = nil;
    HUD.textLabel.text = msg;
    HUD.position = JGProgressHUDPositionBottomCenter;
    HUD.marginInsets = (UIEdgeInsets) {
        .top = 0.0f,
        .bottom = 20.0f,
        .left = 0.0f,
        .right = 0.0f,
    };
    [HUD showInView:MAIN_WINDOW];
    [HUD dismissAfterDelay:2.0];
}

- (void)showPieHUDWithText:(NSString*)str andProgress:(NSInteger)progress
{
    if (nil == self.sharedPitHUD) {
        self.sharedPitHUD = [[JGProgressHUD alloc] initWithStyle:JGProgressHUDStyleDark];
        self.sharedPitHUD.interactionType = JGProgressHUDInteractionTypeBlockTouchesOnHUDView;
        self.sharedPitHUD.animation = [JGProgressHUDFadeZoomAnimation animation];
        self.sharedPitHUD.interactionType = JGProgressHUDInteractionTypeBlockAllTouches;
        self.sharedPitHUD.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
        self.sharedPitHUD.HUDView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.sharedPitHUD.HUDView.layer.shadowOffset = CGSizeZero;
        self.sharedPitHUD.HUDView.layer.shadowOpacity = 0.4f;
        self.sharedPitHUD.HUDView.layer.shadowRadius = 8.0f;
        
        self.sharedPitHUD.indicatorView = [[JGProgressHUDPieIndicatorView alloc] initWithHUDStyle:self.sharedPitHUD.style];
    }

    if (0 == progress) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.sharedPitHUD.layoutChangeAnimationDuration = 0.0;
            [self.sharedPitHUD showInView:MAIN_WINDOW];
            [self.sharedPitHUD setProgress:progress/100.0f animated:YES];
            self.sharedPitHUD.detailTextLabel.text = [NSString stringWithFormat:@"%ld %%", (long)progress];
            self.sharedPitHUD.textLabel.text = str;
        });
    } else if (progress >= 100) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.sharedPitHUD setProgress:1.0f animated:YES];
            self.sharedPitHUD.textLabel.text = str;
            self.sharedPitHUD.detailTextLabel.text = nil;
            
            self.sharedPitHUD.layoutChangeAnimationDuration = 0.3;
            self.sharedPitHUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.sharedPitHUD dismiss];
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.sharedPitHUD setProgress:progress/100.0f animated:YES];
            self.sharedPitHUD.detailTextLabel.text = [NSString stringWithFormat:@"%li", (long)progress];
            self.sharedPitHUD.textLabel.text = str;
        });
    }
    
}

+ (NSString *)createUUID
{
    // Create universally unique identifier (object)
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    // Get the string representation of CFUUID object.
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

+ (NSString*)secretKey
{
    NSString * str = [NSString stringWithFormat:@"%@", @"chetu"];
    NSNumber * h = [NSNumber numberWithDouble:6.6260693];
    NSString * sourceKey = [NSString stringWithFormat:@"%@%@", str, h];
    
    NSMutableArray * shiftArr = [NSMutableArray arrayWithCapacity:sourceKey.length];
    double shift = M_E;
    for (int i = 0; i < sourceKey.length; i++) {
        NSInteger oneShift = shift;
        [shiftArr addObject:[NSNumber numberWithInteger:(oneShift)]];
        shift = (shift - oneShift)*10;
    }
    
    return [sourceKey shiftEachDigit:shiftArr];
}

+ (NSString*)verifyKey:(NSString*)origKey
{
    return [[NSString stringWithFormat:@"%@&%@", origKey, [self secretKey]] MD5];
}

+ (CGFloat) distFrom:(CLLocationCoordinate2D)from toCoor:(CLLocationCoordinate2D)to
{
    CLLocation * loc1 = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation * loc2 = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];
    return [loc1 distanceFromLocation:loc2];
}

+ (CLLocation*) dictToLocation:(NSDictionary*)dict
{
    CLLocationCoordinate2D coor = CLLocationCoordinate2DMake([dict[@"lat"] doubleValue], [dict[@"lon"] doubleValue]);
    if ((coor.latitude == 0 && coor.longitude == 0) || !CLLocationCoordinate2DIsValid(coor)) {
        return nil;
    }
    return [[CLLocation alloc] initWithLatitude:coor.latitude longitude:coor.longitude];
}

+ (BOOL)isEnableDebug {
    NSNumber * enable = [[NSUserDefaults standardUserDefaults] objectForKey:kDebugEnable];
    if (enable && [enable boolValue]) {
        return YES;
    }
    return NO;
}

@end
