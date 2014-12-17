//
//  GToolUtil.h
//  TripMan
//
//  Created by taq on 12/2/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GToolUtil : NSObject

+ (instancetype)sharedInstance;

+ (void)showToast:(NSString*)msg;
- (void)showPieHUDWithText:(NSString*)str andProgress:(NSInteger)progress;

+ (NSString *)createUUID;

@end
