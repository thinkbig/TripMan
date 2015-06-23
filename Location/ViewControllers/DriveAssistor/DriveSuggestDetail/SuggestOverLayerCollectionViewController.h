//
//  SuggestOverLayerCollectionViewController.h
//  TripMan
//
//  Created by taq on 11/20/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTRoute.h"

@interface SuggestOverLayerCollectionViewController : UICollectionViewController

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) TripSummary *     tripSum;
@property (nonatomic, strong) CTRoute *         route;
@property (nonatomic, strong) NSDictionary *    predictDict;

@end
