//
//  AJPropertyDescriptor.h
//  AnyJson
//
//  Created by casa on 14-9-20.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AJClassHelper.h"

@interface AJPropertyDescriptor : NSObject

@property (nonatomic, strong, readonly) NSString *propertyName;

@property (nonatomic, assign, readonly) AJDataType propertyType;
@property (nonatomic, strong, readonly) Class propertyClass;

- (instancetype)initWithPropertyNameString:(NSString *)propertyNameString propertyAttributeString:(NSString *)propertyAttributeString;

@end
