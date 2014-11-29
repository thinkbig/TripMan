//
//  NSAttributedString+Style.h
//  TripMan
//
//  Created by taq on 11/26/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Style)

+ (NSAttributedString*) stringWithNumber:(NSString*)num font:(UIFont*)font1 color:(UIColor*)color1 andUnit:(NSString*)unit font:(UIFont*)font2 color:(UIColor*)color2;

@end
