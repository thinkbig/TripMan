//
//  CTConfigProvider.h
//  TripMan
//
//  Created by taq on 5/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMHint.h"

// 不要修改这个枚举的值，可以添加新的
typedef NS_ENUM(NSUInteger, eShowHint) {
    eShowHintMyTripFirst = 1000,
    
    eShowHintMyTripSwipe,
    eShowHintMyTripDatePicker,
    eShowHintMyTripEditAddress,
    
    eShowHintMyTripLast
};

@interface CTConfigProvider : NSObject

+ (instancetype)sharedInstance;

// url config
- (NSString*) currentServer;
- (NSString*) currentServerName;
- (NSDictionary*) allServerConfigs;
- (void) selectServerWithName:(NSString*)serverName;

// if the hint view has shown for key
// will set as shown after call this method
- (BOOL) hasShowHintForKey:(eShowHint)hintKey;
- (void) resetAllHintKey;

@end
