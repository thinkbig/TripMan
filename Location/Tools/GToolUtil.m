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
            self.sharedPitHUD.textLabel.text = @"完成";
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

+ (NSString *)deviceId
{
    static NSString * kTripManDeviceIdKey = @"kTripManDeviceIdKey";
    NSString * oldId = [[FXKeychain defaultKeychain] objectForKey:kTripManDeviceIdKey];
    if (nil == oldId) {
        oldId = [self createUUID];
        [[FXKeychain defaultKeychain] setObject:oldId forKey:kTripManDeviceIdKey];
    }
    return oldId;
}

@end
