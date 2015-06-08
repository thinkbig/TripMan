//
//  NSString+QRImage.h
//  TripMan
//
//  Created by taq on 6/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (QRImage)

- (UIImage*) qrImageWithSize:(CGFloat)size;
- (UIImage*) qrImageWithSize:(CGFloat)size backgroundColor:(UIColor*)bgColor foregroundColor:(UIColor*)fgColor;
- (UIImage*) qrImageWithSize:(CGFloat)size backgroundColor:(UIColor*)bgColor foregroundColor:(UIColor*)fgColor centerImage:(UIImage*)centerImg;

@end
