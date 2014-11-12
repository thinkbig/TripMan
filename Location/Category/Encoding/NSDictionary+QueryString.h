//
//  NSDictionary+QueryString.h
//  tradeshiftHome
//
//  Created by taq on 11/4/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (QueryString)

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString;

- (NSString *)queryStringValue;

@end
