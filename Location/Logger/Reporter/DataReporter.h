//
//  DataReporter.h
//  TripMan
//
//  Created by taq on 3/2/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataReporter : NSObject

+ (instancetype) sharedInst;

+ (void) asyncUserDeviceInfo;

@end
