//
//  NSString+ShiftEncode.m
//  iphone51buy
//
//  Created by alex tao on 11/28/12.
//  Copyright (c) 2012 icson. All rights reserved.
//

#import "NSString+ShiftEncode.h"

@implementation NSString (ShiftEncode)

- (NSString*) shift:(int)offset
{
    NSInteger len = self.length;
    NSMutableString * decodeStr = [NSMutableString stringWithCapacity:len];
    
    int idx = 0;
    while (idx < len) {
        unichar singleChar = [self characterAtIndex:idx++];
        [decodeStr appendFormat:@"%c", singleChar + offset];
    }
    return decodeStr;
}

- (NSString*) shiftEachDigit:(NSArray*)offsetArr
{
    NSInteger len = self.length;
    NSMutableString * decodeStr = [NSMutableString stringWithCapacity:len];
    
    int idx = 0;
    while (idx < len) {
        long offset = idx < offsetArr.count ? [[offsetArr objectAtIndex:idx] integerValue] : 0;
        unichar singleChar = [self characterAtIndex:idx++];
        [decodeStr appendFormat:@"%ld", singleChar + offset];
    }
    return decodeStr;
}

- (NSString*) reverseString
{
    __weak NSMutableString * retStr = [NSMutableString stringWithCapacity:self.length];
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences) usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [retStr appendString:substring];
    }];
    return retStr;
}

- (NSString*) chinese2Pinyin
{
    if ([self length]) {
        NSMutableString *ms = [[NSMutableString alloc] initWithString:self];
        if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformMandarinLatin, NO)) {
            if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformStripDiacritics, NO)) {
                return [ms copy];
            }
        }
    }
    return nil;
}

@end
