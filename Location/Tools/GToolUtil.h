//
//  GToolUtil.h
//  TripMan
//
//  Created by taq on 12/2/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GToolUtil : NSObject

@property (nonatomic, strong) NSString *            deviceId;
@property (nonatomic, strong) NSString *            userId;

+ (instancetype)sharedInstance;

+ (void)showToast:(NSString*)msg;
- (void)showPieHUDWithText:(NSString*)str andProgress:(NSInteger)progress;

+ (NSString *)createUUID;
+ (NSString*)verifyKey:(NSString*)origKey;

+ (CGFloat) distFrom:(CLLocationCoordinate2D)from toCoor:(CLLocationCoordinate2D)to;
+ (CLLocation*) dictToLocation:(NSDictionary*)dict;

@end
