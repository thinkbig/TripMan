//
//  AJObject2JsonSerializer.m
//  AnyJson
//
//  Created by casa on 14-9-22.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import "AJObject2JsonSerializer.h"
#import "AJPropertyDescriptor.h"
#import "NSData+Base64.h"

@implementation AJObject2JsonSerializer

#pragma mark - public methods
+ (id)serializeToBasicObject:(id)rawObject excludeProps:(NSArray*)excludes
{
    if (rawObject == NULL || rawObject == nil || [rawObject isKindOfClass:[NSNull class]]) {
        return [NSNull null];
    }
    
    // now, we are step into customized object zone
    NSDictionary *propertiesMap = [AJClassHelper reflectProperties:[rawObject class]];
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (AJPropertyDescriptor *propertyDescriptor in propertiesMap.allValues) {
        if ([excludes containsObject:propertyDescriptor.propertyName]) {
            continue;
        }
        id property = [rawObject valueForKey:propertyDescriptor.propertyName];
        if (nil == property) {
            continue;
        }
        
        if (propertyDescriptor.propertyType > AJDataTypeJsonableObject && propertyDescriptor.propertyType < AJDataTypePrimitiveType) {
            result[propertyDescriptor.propertyName] = [AJObject2JsonSerializer jsonableObject:property dataType:propertyDescriptor.propertyType];
        }
        
        if (propertyDescriptor.propertyType > AJDataTypePrimitiveType && propertyDescriptor.propertyType < AJDataTypeComplicateType) {
            result[propertyDescriptor.propertyName] = [AJObject2JsonSerializer jsonablePrimitiveValue:property dataType:propertyDescriptor.propertyType];
        }
        
        if (propertyDescriptor.propertyType > AJDataTypeComplicateType && propertyDescriptor.propertyType < AJDataTypeCustomizedObject) {
            result[propertyDescriptor.propertyName] = [AJObject2JsonSerializer jsonableComplicateValue:property dataType:propertyDescriptor.propertyType];
        }
        
        if (propertyDescriptor.propertyType == AJDataTypeCustomizedObject) {
            result[propertyDescriptor.propertyName] = [AJObject2JsonSerializer serializeToBasicObject:property excludeProps:excludes];
        }
    }
    return result;
}

#pragma mark - private methods

+ (id)jsonableComplicateValue:(id)rawObject dataType:(AJDataType)dataType
{
    if (dataType == AJDataTypeCharString) {
        NSLog(@"%@", rawObject);
    }
    return @"N/A";
}

+ (id)jsonablePrimitiveValue:(id)rawObject dataType:(AJDataType)dataType
{
    if (dataType == AJDataTypeChar) {
        char charString[] = {[rawObject charValue], '\0'};
        return [NSString stringWithCString:charString encoding:NSUTF8StringEncoding];
    }
    
    if (dataType == AJDataTypeCPPBool) {
        return @([rawObject boolValue]);
    }
    
    return @([rawObject integerValue]);
}

+ (id)jsonableObject:(id)rawObject dataType:(AJDataType)dataType
{
    if (dataType == AJDataTypeNSArray) {
        NSMutableArray *result = [NSMutableArray new];
        for (id item in rawObject) {
            [result addObject:[AJObject2JsonSerializer serializeToBasicObject:item excludeProps:nil]];
        }
        return result;
    }
    
    if (dataType == AJDataTypeNSDictionary) {
        NSMutableDictionary *result = [NSMutableDictionary new];
        for (id key in [rawObject allKeys]) {
            NSString *propertyKey;
            if ([key isKindOfClass:[NSString class]]) {
                propertyKey = key;
            } else {
                propertyKey = [NSString stringWithFormat:@"%@^%@", [NSString stringWithCString:object_getClassName(key) encoding:NSUTF8StringEncoding], [[NSUUID UUID] UUIDString]];
            }
            
            id item = rawObject[key];
            result[propertyKey] = [AJObject2JsonSerializer serializeToBasicObject:item excludeProps:nil];
        }
        return result;
    }
    
    if (dataType == AJDataTypeNSDate) {
        return @((unsigned long long)([rawObject timeIntervalSince1970]));
    }
    
    if (dataType == AJDataTypeNSData) {
        return [((NSData*)rawObject) base64EncodedString];
    }
    
    if (dataType == AJDataTypeNSNumber) {
        return rawObject;
    }
    
    if (dataType == AJDataTypeNSString) {
        return rawObject;
    }
    
    return [NSNull null];
}

@end
