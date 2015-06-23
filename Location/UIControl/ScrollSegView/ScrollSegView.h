//
//  ScrollSegView.h
//  TripMan
//
//  Created by taq on 12/18/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ScrollSegSelBlock)(NSUInteger selIdx);

@interface ScrollSegView : UIScrollView

@property (nonatomic, strong) NSArray *             segStrings;
@property (nonatomic, copy) ScrollSegSelBlock       selBlock;
@property (nonatomic, strong) UIColor *             normalTextColor;
@property (nonatomic, strong) UIColor *             hightLightTextColor;
@property (nonatomic) NSUInteger                    selIdx;

@end
