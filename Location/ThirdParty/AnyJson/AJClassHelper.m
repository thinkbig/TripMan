//
//  AJClassHelper.m
//  AnyJson
//
//  Created by casa on 14-9-20.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import "AJClassHelper.h"
#import <objc/runtime.h>
#import "AJPropertyDescriptor.h"

@implementation AJClassHelper

+ (NSDictionary *)reflectProperties:(Class)clazz
{
//    Class superClass = [clazz superclass];
//    NSDictionary *superClassPropertyMap = nil;
//    if (superClass != NULL && superClass != [NSObject class]) {
//        superClassPropertyMap = [AJClassHelper reflectProperties:superClass];
//    }
    
    unsigned int outCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(clazz, &outCount);
    NSMutableDictionary *propertyMap = [NSMutableDictionary dictionary];//[[NSMutableDictionary alloc] initWithDictionary:superClassPropertyMap];
    
    for (int index = 0; index < outCount; index++) {
        const char *propertyName = property_getName(propertyList[index]);
        NSString *propertyNameString = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        
        const char *propertyAttribute = property_getAttributes(propertyList[index]);
        NSString *propertyAttributeString = [NSString stringWithCString:propertyAttribute encoding:NSUTF8StringEncoding];
        
        AJPropertyDescriptor *propertyDescriptor = [[AJPropertyDescriptor alloc] initWithPropertyNameString:propertyNameString propertyAttributeString:propertyAttributeString];
        propertyMap[propertyNameString] = propertyDescriptor;
    }
    
    free(propertyList);
    
    return propertyMap;
}

+ (Class)classFromPropertyAttributeString:(NSString *)propertyAttributeString
{
    NSRange range = [propertyAttributeString rangeOfString:@","];
    if (range.location == NSNotFound) {
        return nil;
    }
    
    NSString *typeString = [propertyAttributeString substringToIndex:range.location];
    if ([typeString hasPrefix:@"T@\""]) {
        NSUInteger length = typeString.length;
        return NSClassFromString([typeString substringWithRange:NSMakeRange(3, length - 4)]);
    }
    
    return nil;
}

+ (AJDataType)dataTypeOfClass:(Class)clazz
{
    if (clazz == [NSArray class]) {
        return AJDataTypeNSArray;
    }
    if (clazz == [NSDictionary class]) {
        return AJDataTypeNSDictionary;
    }
    if (clazz == [NSString class]) {
        return AJDataTypeNSString;
    }
    if (clazz == [NSDate class]) {
        return AJDataTypeNSDate;
    }
    if (clazz == [NSData class]) {
        return AJDataTypeNSData;
    }
    if (clazz == [NSNumber class]) {
        return AJDataTypeNSNumber;
    }
    
    return AJDataTypeCustomizedObject;
}



+ (AJDataType)propertyTypeFromPropertyAttributeString:(NSString *)propertyAttributeString
{
    NSRange range = [propertyAttributeString rangeOfString:@","];
    if (range.location == NSNotFound) {
        return AJDataTypeError;
    }
    
    NSString *typeString = [propertyAttributeString substringToIndex:range.location];
    
    if ([typeString hasPrefix:@"T@"]) {
        NSUInteger length = typeString.length;
        Class clazz = NSClassFromString([typeString substringWithRange:NSMakeRange(3, length - 4)]);
        return [AJClassHelper dataTypeOfClass:clazz];
    }
    
    if ([typeString hasPrefix:@"Tc"]) {
        return AJDataTypeChar;
    }
    if ([typeString hasPrefix:@"Td"]) {
        return AJDataTypeDouble;
    }
    if ([typeString hasPrefix:@"Ti"]) {
        return AJDataTypeInt;
    }
    if ([typeString hasPrefix:@"Tf"]) {
        return AJDataTypeFloat;
    }
    if ([typeString hasPrefix:@"Tl"]) {
        return AJDataTypeLong;
    }
    if ([typeString hasPrefix:@"Ts"]) {
        return AJDataTypeShort;
    }
    if ([typeString hasPrefix:@"T{"]) {
        return AJDataTypeStructure;
    }
    if ([typeString hasPrefix:@"TI"]) {
        return AJDataTypeUnsigned;
    }
    if ([typeString hasPrefix:@"T?"]) {
        return AJDataTypeUnknownType;
    }
    if ([typeString hasPrefix:@"Tv"]) {
        return AJDataTypeVoid;
    }
    if ([typeString hasPrefix:@"Tq"]) {
        return AJDataTypeLongLong;
    }
    if ([typeString hasPrefix:@"TC"]) {
        return AJDataTypeUnsignedChar;
    }
    if ([typeString hasPrefix:@"TS"]) {
        return AJDataTypeUnsignedShort;
    }
    if ([typeString hasPrefix:@"TL"]) {
        return AJDataTypeUnsignedLong;
    }
    if ([typeString hasPrefix:@"TQ"]) {
        return AJDataTypeUnsignedLongLong;
    }
    if ([typeString hasPrefix:@"TB"]) {
        return AJDataTypeCPPBool;
    }
    if ([typeString hasPrefix:@"T*"] || [typeString hasPrefix:@"Tr*"]) {
        return AJDataTypeCharString;
    }
    if ([typeString hasPrefix:@"T#"]) {
        return AJDataTypeClass;
    }
    if ([typeString hasPrefix:@"T:"]) {
        return AJDataTypeSelector;
    }
    if ([typeString hasPrefix:@"T["]) {
        return AJDataTypeArray;
    }
    if ([typeString hasPrefix:@"T{"]) {
        return AJDataTypeStructure;
    }
    if ([typeString hasPrefix:@"T("]) {
        return AJDataTypeUnion;
    }
    if ([typeString hasPrefix:@"Tb"]) {
        return AJDataTypeBitField;
    }
    if ([typeString hasPrefix:@"T^"]) {
        return AJDataTypePointer;
    }
    
    return AJDataTypeError;
}

@end
