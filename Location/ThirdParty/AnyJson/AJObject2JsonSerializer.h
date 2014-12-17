//
//  AJObject2JsonSerializer.h
//  AnyJson
//
//  Created by casa on 14-9-22.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AJObject2JsonSerializer : NSObject

+ (id)serializeToBasicObject:(id)rawObject excludeProps:(NSArray*)excludes;

@end
