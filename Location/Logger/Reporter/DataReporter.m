//
//  DataReporter.m
//  TripMan
//
//  Created by taq on 3/2/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "DataReporter.h"
#import "CTWakeupFacade.h"

@implementation DataReporter

+ (instancetype)sharedInst {
    static DataReporter *_sharedInst = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInst = [[self alloc] init];
    });
    
    return _sharedInst;
}

+ (void) asyncUserDeviceInfo
{
    static BOOL asyncing = NO;
    
    if (!asyncing) {
        asyncing = YES;
        CTWakeupFacade * facade = [[CTWakeupFacade alloc] init];
        [facade requestWithSuccess:^(id result) {
            asyncing = NO;
            NSLog(@"result = %@", result);
        } failure:^(NSError * err) {
            asyncing = NO;
            NSLog(@"%@", err);
        }];
    }
}

@end
