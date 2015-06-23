//
//  CarHomeViewController.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "PICircularProgressView.h"
#import "CarMaintainInfo.h"
#import "WXApi.h"
#import "WXApiObject.h"

@interface CarHomeViewController : GViewController <WXApiDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *homeCollection;

@property (nonatomic, strong) CarMaintainInfo *     maintainInfo;

@end
