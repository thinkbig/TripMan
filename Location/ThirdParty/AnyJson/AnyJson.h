//
//  AnyJson.h
//  AnyJson
//
//  Created by casa on 14-9-19.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#ifndef AnyJson_AnyJson_h
#define AnyJson_AnyJson_h

#import "AJSerializer.h"
#import <objc/runtime.h>

@protocol AJSerializable <NSObject>

@required
- (Class)classForPropertyName:(NSString *)propertyName;

@end


#endif
