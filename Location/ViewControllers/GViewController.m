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

@interface GViewController ()

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
        [self.currentHUD dismissAnimated:YES];
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

- (void)showToast:(NSString*)msg
{
    if (msg.length > 0) {
        JGProgressHUD *HUD = [self prototypeHUD:NO];
        HUD.indicatorView = nil;
        HUD.textLabel.text = msg;
        HUD.position = JGProgressHUDPositionBottomCenter;
        HUD.marginInsets = (UIEdgeInsets) {
            .top = 0.0f,
            .bottom = 20.0f,
            .left = 0.0f,
            .right = 0.0f,
        };
        [HUD showInView:self.view];
        [HUD dismissAfterDelay:2.0];
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
