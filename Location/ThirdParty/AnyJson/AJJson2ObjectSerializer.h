//
//  AJJson2ObjectSerializer.h
//  AnyJson
//
//  Created by casa on 14-9-22.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AJJson2ObjectSerializer : NSObject

+ (id)transformJsonObject:(id)jsonObject toTargetObjectClass:(Class)targetClass;

@end
