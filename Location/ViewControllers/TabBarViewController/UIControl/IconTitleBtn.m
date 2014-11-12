//
//  AddConnBtn.m
//  tradeshiftHome
//
//  Created by taq on 9/24/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "IconTitleBtn.h"

@implementation IconTitleBtn

- (void)internalInit
{
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return UIEdgeInsetsInsetRect(self.bounds, self.titleEdgeInsets);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return UIEdgeInsetsInsetRect(self.bounds, self.imageEdgeInsets);
}


@end
