//
//  SuggestDetailViewController.h
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "BMapKit.h"
#import "A3ParallaxScrollView.h"
#import "CTRoute.h"
#import "BMapBaseViewController.h"

@interface SuggestDetailViewController : BMapBaseViewController <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet A3ParallaxScrollView *rootScrollView;

@property (nonatomic, strong) CTRoute *         route;
@property (nonatomic, strong) NSString *        endParkingId;       // 如果有

@end
