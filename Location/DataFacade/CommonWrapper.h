//
//  CommonWrapper.h
//  Location
//
//  Created by taq on 11/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonFacadeDefine.h"

@interface CommonWrapper : NSObject

@property (nonatomic, copy) successFacadeBlock          successBlock;
@property (nonatomic, copy) failureFacadeBlock          failureBlock;

// just makes sure the api is the same 
- (void)requestWithSuccess:(successFacadeBlock)success failure:(failureFacadeBlock)failure;


// Subclass may inherite the functions below

// In case the child facade do some caching. return nil for no custom cache
- (id) cachedResult;

- (void) realSendRequest;

@end
