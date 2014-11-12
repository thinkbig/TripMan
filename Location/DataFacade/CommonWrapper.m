//
//  CommonWrapper.m
//  Location
//
//  Created by taq on 11/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CommonWrapper.h"

@implementation CommonWrapper

- (void)requestWithSuccess:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    id cachedResult = [self cachedResult];
    if (cachedResult) {
        if (success) {
            success(cachedResult);
        }
        return;
    }
    
    [self realSendRequest];
}

- (id) cachedResult {
    return nil;
}

- (void) realSendRequest {
    NSLog(@"please override this function %@ in subclass", NSStringFromSelector(_cmd));
}

@end
