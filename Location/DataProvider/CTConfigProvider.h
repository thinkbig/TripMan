//
//  CTConfigProvider.h
//  TripMan
//
//  Created by taq on 5/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTConfigProvider : NSObject

+ (instancetype)sharedInstance;

// url config
- (NSString*) currentServer;
- (NSString*) currentServerName;
- (NSDictionary*) allServerConfigs;
- (void) selectServerWithName:(NSString*)serverName;

@end
