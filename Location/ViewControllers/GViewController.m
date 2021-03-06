//
//  GViewController.m
//  tradeshiftHome
//
//  Created by taq on 5/13/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "GViewController.h"
#import "JGProgressHUD.h"
#import "JGProgressHUDFadeZoomAnimation.h"
#import <objc/runtime.h>

static const NSString * kHUDDismissKey = @"CT_prop_kHUDDismissKey";

@interface GViewController () <JGProgressHUDDelegate>

@property (nonatomic, strong) UIRefreshControl *        pullRefresh;
@property (nonatomic, strong) JGProgressHUD *           currentHUD;

@end

@implementation GViewController

- (void) internalInit {
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self internalInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        [self internalInit];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.isAccessibilityElement = NO;
}

- (JGProgressHUD *)prototypeHUD:(BOOL)isModel
{
    JGProgressHUD *HUD = [[JGProgressHUD alloc] initWithStyle:JGProgressHUDStyleDark];
    HUD.interactionType = isModel ? JGProgressHUDInteractionTypeBlockAllTouches : JGProgressHUDInteractionTypeBlockTouchesOnHUDView;
    HUD.animation = [JGProgressHUDFadeZoomAnimation animation];
    HUD.HUDView.layer.shadowColor = [UIColor blackColor].CGColor;
    HUD.HUDView.layer.shadowOffset = CGSizeZero;
    HUD.HUDView.layer.shadowOpacity = 0.4f;
    HUD.HUDView.layer.shadowRadius = 8.0f;
    
    return HUD;
}

- (void)showLoading
{
    self.isLoading = YES;
    if (self.currentHUD) {
        return;
    }
    self.currentHUD = [self prototypeHUD:YES];
    self.currentHUD.textLabel.text = @"载入中...";
    
    [self.currentHUD showInView:self.view];
}

- (void)showLoadingNonModel
{
    self.isLoading = YES;
    if (self.currentHUD) {
        [self.currentHUD dismissAnimated:YES];
    }
    JGProgressHUD *HUD = [self prototypeHUD:NO];
    HUD.textLabel.text = @"载入中...";
    
    [HUD showInView:self.view];
}

- (void)showToast:(NSString*)msg onDismiss:(void (^)(id))handler {
    [self showToastWithErr:nil defaultMsg:msg onDismiss:handler];
}

- (void)showToastWithErr:(NSError*)err defaultMsg:(NSString*)msg onDismiss:(void (^)(id))handler
{
    msg = [GToolUtil msgWithErr:err andDefaultMsg:msg];
    if (msg.length > 0) {
        JGProgressHUD *HUD = [self prototypeHUD:NO];
        HUD.indicatorView = nil;
        HUD.textLabel.text = msg;
        HUD.position = JGProgressHUDPositionCenter;
        HUD.marginInsets = (UIEdgeInsets) {
            .top = 0.0f,
            .bottom = 0.0f,
            .left = 0.0f,
            .right = 0.0f,
        };
        if (handler) {
            HUD.delegate = self;
            objc_setAssociatedObject(HUD, &kHUDDismissKey, handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        
        HUD.accessibilityLabel = HUD.accessibilityIdentifier = @"Error";
        [HUD showInView:self.view];
        [HUD dismissAfterDelay:2.5];
    }
}

- (void)hideLoading
{
    [self.currentHUD dismissAnimated:YES];
    self.currentHUD = nil;
    self.isLoading = NO;
}

- (void)addPullRefreshOn:(UICollectionView*)collectionView withSelector:(SEL)selector
{
    if ([collectionView isKindOfClass:[UICollectionView class]])
    {
        if (nil == self.pullRefresh) {
            self.pullRefresh = [[UIRefreshControl alloc] init];
            self.pullRefresh.tintColor = [UIColor darkGrayColor];
            [self.pullRefresh addTarget:self action:selector forControlEvents:UIControlEventValueChanged];
        }
        [collectionView addSubview:_pullRefresh];
        collectionView.alwaysBounceVertical = YES;
    }
}

@end
