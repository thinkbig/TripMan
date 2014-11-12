//
//  NSString+MD5.h
//  Location
//
//  Created by taq on 10/20/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MD5)

- (NSString *)MD5;
- (NSData*)MD5CharData;

- (NSString*)urlEncoding;

@end
