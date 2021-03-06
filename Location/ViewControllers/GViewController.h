//
//  GViewController.h
//  tradeshiftHome
//  a global viewcontroller for common stuff, currently do nothing
//
//  Created by taq on 5/13/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonDefine.h"
#import "UIView+Frame.h"

@interface GViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic) BOOL                              isLoading;

// subview should override it to do init issue
- (void) internalInit;

- (void)showLoading;
- (void)showLoadingNonModel;
- (void)hideLoading;

- (void)showToast:(NSString*)msg onDismiss:(void (^)(id))handler;
- (void)showToastWithErr:(NSError*)err defaultMsg:(NSString*)msg onDismiss:(void (^)(id))handler;

// only for collectionview
- (void)addPullRefreshOn:(UICollectionView*)collectionView withSelector:(SEL)selector;

@end
