//
//  TSTabBar.m
//  tradeshiftHome
//
//  Created by taq on 7/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSTabBar.h"
#import "TSTabBarConfig.h"
#import "TSTabBarItem.h"
#import "UIControl+Blocks.h"

@interface TSTabBar()

@property (nonatomic, strong) NSArray *             buttons;

@end

@implementation TSTabBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.devideLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 1)];
        [self.devideLineImageView setBackgroundColor:[UIColor darkGrayColor]];
        [self addSubview:self.devideLineImageView];
        
        self.backgroundImageView = [[UIImageView alloc] initWithImage:[self defaultBackgroundImage]];
        self.backgroundImageView.contentMode = UIViewContentModeBottom;
        self.backgroundImageView.center = CGPointMake(self.center.x, self.frame.size.height/2);
        self.backgroundImageView.backgroundColor = [UIColor clearColor];
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:self.backgroundImageView];
        
        self.selectedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.height, frame.size.height)];
        self.selectedImageView.image = [self defaultSelectionIndicatorImage];
        self.selectedImageView.contentMode = UIViewContentModeScaleToFill;
        self.selectedImageView.backgroundColor = [UIColor clearColor];
        self.selectedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:self.selectedImageView];
    }
    return self;
}

- (void)setTabShadowImage:(UIImage*)image
{
    if (image) {
        self.devideLineImageView.image = image;
        self.devideLineImageView.backgroundColor = [UIColor clearColor];
        CGSize imgSz = image.size;
        CGSize frameSz = self.bounds.size;
        self.devideLineImageView.frame = CGRectMake((frameSz.width-imgSz.width)/2, -imgSz.height, imgSz.width, imgSz.height);
    }
}

- (void)setItemModels:(NSArray*)itemModels
{
    if (itemModels.count == 0) {
        return;
    }
    for (UIButton* button in self.buttons) {
        [button removeActionCompletionBlocksForControlEvents:UIControlEventTouchUpInside];
        [button removeFromSuperview];
    }
    
    NSMutableArray* newButtons = [NSMutableArray array];
    
    NSUInteger offset = 0;
    if (self.frame.size.width >= 768) {
        offset = self.frame.size.width / 4;
    }
    CGSize buttonSize = CGSizeMake((self.frame.size.width - offset * 2) / itemModels.count, self.frame.size.height);
    
    [itemModels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        TSTabBarItemModel * model = (TSTabBarItemModel*)obj;
        TSTabBarItem* button = [[TSTabBarItem alloc] initWithFrame:CGRectMake(idx * buttonSize.width + offset, 0, buttonSize.width, buttonSize.height)];
        if (model.itemTitle) {
            [button setTitle:model.itemTitle forState:UIControlStateNormal];
            button.imageEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 20.0, 5.0);
            button.titleEdgeInsets = UIEdgeInsetsMake(30.0, 2.0, 5.0, 2.0);
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        }
        button.itemModel = model;
        [button addActionCompletionBlock:^(id sender) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(tabBar:clickItemAtIndex:currentIndex:)]) {
                [self.delegate tabBar:self clickItemAtIndex:idx currentIndex:_selectedIndex];
            }
            [self setSelectedIndex:idx animed:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        
        if (idx == self.selectedIndex) {
            [button setImage:[button imageForState:UIControlStateSelected] forState:UIControlStateNormal];
            self.selectedImageView.center = button.center;
        }
        
        [self addSubview:button];
        [newButtons addObject:button];
    }];

    self.buttons = newButtons;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex animed:(BOOL)animed;
{
    if (selectedIndex < [self.buttons count]) {
        [self willChangeValueForKey:@"selectedIndex"];
        if (self.delegate && [self.delegate respondsToSelector:@selector(tabBar:willSelectItemAtIndex:currentIndex:)]) {
            [self.delegate tabBar:self willSelectItemAtIndex:selectedIndex currentIndex:_selectedIndex];
        }
        
        if (_selectedIndex < [self.buttons count]) {
            UIButton* oldButton = [self.buttons objectAtIndex:_selectedIndex];
            oldButton.selected = NO;
        }
        UIButton* newButton = [self.buttons objectAtIndex:selectedIndex];
        
        void (^comBlock)(BOOL) = ^(BOOL finished) {
            newButton.selected = YES;
            self.selectedImageView.center = newButton.center;
            
            NSUInteger prviousIndex = _selectedIndex;
            self.selectedIndex = selectedIndex;
            
            [self.buttons enumerateObjectsUsingBlock:^(UIButton * obj, NSUInteger idx, BOOL *stop) {
                if (idx != _selectedIndex) {
                    obj.selected = NO;
                }
            }];
            
            [self didChangeValueForKey:@"selectedIndex"];
            if (self.delegate && [self.delegate respondsToSelector:@selector(tabBar:didSelectItemAtIndex:prviousIndex:)]) {
                [self.delegate tabBar:self didSelectItemAtIndex:_selectedIndex prviousIndex:prviousIndex];
            }
        };
        
        if (animed) {
            [UIView animateWithDuration:0.1 animations:^{
                newButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    newButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.2, 1.2);
                    self.selectedImageView.center = newButton.center;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 animations:^{
                        newButton.transform = CGAffineTransformIdentity;
                    } completion:comBlock];
                }];
            }];
        } else {
            comBlock(YES);
        }
    }
}

- (void)setBadge:(NSString*)badgeStr forIndex:(NSUInteger)idx;
{
    if (idx < [self.buttons count]) {
        TSTabBarItem* newButton = [self.buttons objectAtIndex:idx];
        [newButton setItemBadge:badgeStr];
    }
}

- (UIImage*)defaultBackgroundImage
{
    CGFloat width = 2048;
    // Get the image that will form the top of the background
    UIImage* topImage = [UIImage imageNamed:tabBarBgImage];
    
    // Create a new image context
    //UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, topImage.size.height*2 + 5), NO, 0.0);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, self.frame.size.height), NO, 0.0);
    
    // Create a stretchable image for the top of the background and draw it
    UIImage* stretchedTopImage = [topImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    //[stretchedTopImage drawInRect:CGRectMake(0, 5, width, topImage.size.height)];
    [stretchedTopImage drawInRect:CGRectMake(0, 0, width, topImage.size.height)];
    
    // Generate a new image
    UIImage* resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

- (UIImage*)defaultSelectionIndicatorImage {
    return [UIImage imageNamed:tabBarHightLightImage];
}


@end
