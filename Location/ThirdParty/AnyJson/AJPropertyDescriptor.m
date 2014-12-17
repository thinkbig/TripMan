//
//  AJPropertyDescriptor.m
//  AnyJson
//
//  Created by casa on 14-9-20.
//  Copyright (c) 2014年 casa. All rights reserved.
//

#import "AJPropertyDescriptor.h"

@interface AJPropertyDescriptor ()

@property (nonatomic, strong) NSString *propertyName;
@property (nonatomic, assign) AJDataType propertyType;

@property (nonatomic, strong) Class propertyClass;

@end

@implementation AJPropertyDescriptor

#pragma mark - public methods
- (instancetype)initWithPropertyNameString:(NSString *)propertyNameString propertyAttributeString:(NSString *)propertyAttributeString;
{
    self = [super init];
    
    if (self) {
        self.propertyName = propertyNameString;
        self.propertyClass = [AJClassHelper classFromPropertyAttributeString:propertyAttributeString];
        self.propertyType = [AJClassHelper propertyTypeFromPropertyAttributeString:propertyAttributeString];
    }
    
    return self;
}

@end
