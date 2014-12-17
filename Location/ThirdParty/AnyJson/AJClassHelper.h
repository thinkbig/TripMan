//
//  AJClassHelper.h
//  AnyJson
//
//  Created by casa on 14-9-20.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AJDataType) {
    
    AJDataTypeError = 0,
    
    // JSONable class types
    AJDataTypeJsonableObject = 100,
    AJDataTypeNSArray = 101,
    AJDataTypeNSDictionary = 102,
    AJDataTypeNSDate = 103,
    AJDataTypeNSData = 104,
    AJDataTypeNSString = 105,
    AJDataTypeNSNumber = 106,
    
    // primitive types
    AJDataTypePrimitiveType = 200,
    AJDataTypeChar = 201,
    AJDataTypeDouble = 202,
    AJDataTypeFloat = 203,
    AJDataTypeInt = 204,
    AJDataTypeLong = 205,
    AJDataTypeShort = 206,
    AJDataTypeUnsigned = 207,
    AJDataTypeLongLong = 208,
    AJDataTypeUnsignedChar = 209,
    AJDataTypeUnsignedShort = 210,
    AJDataTypeUnsignedLong = 211,
    AJDataTypeUnsignedLongLong = 212,
    AJDataTypeCPPBool = 213,
    
    // hard for me to transform, but I will work it out
    AJDataTypeComplicateType = 220,
    AJDataTypeArray = 221,
    AJDataTypeStructure = 222,
    AJDataTypeUnion = 223,
    AJDataTypeBitField = 224,
    AJDataTypeCharString = 215,
    AJDataTypeVoid = 216,
    
    // hmmm...harder...
    AJDataTypeHarderType = 240,
    AJDataTypeSelector = 241,
    AJDataTypeClass = 242,
    AJDataTypePointer = 243,
    AJDataTypeUnknownType = 244, // sometimes it could be a function pointer
    
    // other objects which can not be transformed to JSON directly
    AJDataTypeCustomizedObject = 301,
};

@interface AJClassHelper : NSObject

+ (NSDictionary *)reflectProperties:(Class)clazz;

+ (Class)classFromPropertyAttributeString:(NSString *)propertyAttributeString;
+ (AJDataType)propertyTypeFromPropertyAttributeString:(NSString *)propertyAttributeString;
+ (AJDataType)dataTypeOfClass:(Class)clazz;

@end
