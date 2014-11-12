//
//  TSTabBarItem.h
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IconTitleBtn.h"
#import "CustomBadge.h"

@interface TSTabBarItemModel : NSObject

@property (nonatomic) NSInteger             itemIndex;
@property (nonatomic, strong) UIImage *     itemImage;
@property (nonatomic, strong) UIImage *     itemSelectedImage;
@property (nonatomic, strong) NSString *    itemTitle;

@end


@interface TSTabBarItem : IconTitleBtn

@property (nonatomic, strong) TSTabBarItemModel *       itemModel;
@property (nonatomic, strong) CustomBadge *             badgeValueView;

- (void)setItemBadge:(NSString*)str;

@end
