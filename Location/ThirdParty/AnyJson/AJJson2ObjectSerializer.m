//
//  AJJson2ObjectSerializer.m
//  AnyJson
//
//  Created by casa on 14-9-22.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import "AJJson2ObjectSerializer.h"
#import "AJClassHelper.h"
#import "AJPropertyDescriptor.h"

@implementation AJJson2ObjectSerializer

#pragma mark - public methods
+ (id)transformJsonObject:(id)jsonObject toTargetObjectClass:(Class)targetClass
{
    if (jsonObject == nil || [jsonObject isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    AJDataType targetDataType = [AJClassHelper dataTypeOfClass:targetClass];
    
    NSDictionary *propertyList = [AJClassHelper reflectProperties:targetClass];
    for (AJPropertyDescriptor *propertyDescriptor in propertyList) {
        /*
         NSNumber -> BOOL, NSInteger, Float, Double, Long, NSNumber, NSDate
         NSString -> NSString
         for each NSArray -> object
         for each NSDictionary -> key:object
         */
//        if () {
//        }
    }
    
    
    return nil;
}

@end
