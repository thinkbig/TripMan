//
//  UIViewController+InputScroller.m
//  tradeshiftHome
//
//  Created by taq on 10/30/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "UIViewController+InputScroller.h"
#import "MVTextInputsScroller.h"
#import <objc/runtime.h>

static NSString * KPropetyAutoScroll = @"__KPropetyAutoScroll__";

@implementation UIViewController (InputScroller)

- (BOOL) enableAutoScrollerOn:(UIScrollView*)scrollView
{
    if (scrollView) {
        NSMutableArray * scollerArr = objc_getAssociatedObject(self, &KPropetyAutoScroll);
        if (nil == scollerArr) {
            scollerArr = [NSMutableArray array];
            objc_setAssociatedObject(self, &KPropetyAutoScroll, scollerArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        for (MVTextInputsScroller * scroller in scollerArr) {
            if (scrollView == [scroller monitoringScrollView]) {
                return YES;
            }
        }
        MVTextInputsScroller * newScroller = [[MVTextInputsScroller alloc] initWithScrollView:scrollView];
        [scollerArr addObject:newScroller];
        return YES;
    }
    return NO;
}

@end
