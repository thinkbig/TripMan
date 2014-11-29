//
//  NSAttributedString+Style.m
//  TripMan
//
//  Created by taq on 11/26/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "NSAttributedString+Style.h"

@implementation NSAttributedString (Style)

+ (NSAttributedString*) stringWithNumber:(NSString*)num font:(UIFont*)font1 color:(UIColor*)color1 andUnit:(NSString*)unit font:(UIFont*)font2 color:(UIColor*)color2
{
    NSString * rawStr = [NSString stringWithFormat:@"%@ %@", num, unit];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:rawStr];
    
    // set font
    [attrStr addAttribute:NSFontAttributeName value:font1 range:NSMakeRange(0, num.length)];
    [attrStr addAttribute:NSFontAttributeName value:font2 range:NSMakeRange(num.length, unit.length+1)];
    
    // set color
    if ([color1 isEqual:color2]) {
        [attrStr addAttribute:NSForegroundColorAttributeName value:color1 range:NSMakeRange(0, rawStr.length)];
    } else {
        [attrStr addAttribute:NSForegroundColorAttributeName value:color1 range:NSMakeRange(0, num.length)];
        [attrStr addAttribute:NSForegroundColorAttributeName value:color2 range:NSMakeRange(num.length, unit.length+1)];
    }

    return attrStr;
}

@end
