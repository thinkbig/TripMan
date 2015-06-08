//
//  NSString+QRImage.m
//  TripMan
//
//  Created by taq on 6/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "NSString+QRImage.h"

@implementation NSString (QRImage)

- (UIImage*) qrImageWithSize:(CGFloat)size
{
    CIImage * ciImage = [self _qrImage];
    UIImage * outImg = [self _qrImage:ciImage withSize:size ancCenterImage:nil];
    return outImg;
}

- (UIImage*) qrImageWithSize:(CGFloat)size backgroundColor:(UIColor*)bgColor foregroundColor:(UIColor*)fgColor
{
    CIImage * ciImage = [self _qrImageWithBackgroundColor:bgColor foregroundColor:fgColor];
    UIImage * outImg = [self _qrImage:ciImage withSize:size ancCenterImage:nil];
    return outImg;
}

- (UIImage*) qrImageWithSize:(CGFloat)size backgroundColor:(UIColor*)bgColor foregroundColor:(UIColor*)fgColor centerImage:(UIImage*)centerImg
{
    CIImage * ciImage = [self _qrImageWithBackgroundColor:bgColor foregroundColor:fgColor];
    UIImage * outImg = [self _qrImage:ciImage withSize:size ancCenterImage:centerImg];
    return outImg;
}

- (CIImage*) _qrImage
{
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    return [filter outputImage];
}

- (CIImage*) _qrImageWithBackgroundColor:(UIColor*)bgColor foregroundColor:(UIColor*)fgColor
{
    CIImage * origImage = [self _qrImage];
    
    CIColor * bgCiColor = [CIColor colorWithCGColor:bgColor.CGColor];
    CIColor * fgCiColor = [CIColor colorWithCGColor:fgColor.CGColor];
    CIFilter * filterColor = [CIFilter filterWithName:@"CIFalseColor" keysAndValues:@"inputImage", origImage, @"inputColor0", fgCiColor, @"inputColor1", bgCiColor, nil];
    
//    CIFilter *filter = [CIFilter filterWithName:@"CIMaskToAlpha"];
//    [filter setValue:[filterColor outputImage] forKey:kCIInputImageKey];
//    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    return filterColor.outputImage;
}

- (UIImage*) _qrImage:(CIImage*)qrImage withSize:(CGFloat)size ancCenterImage:(UIImage*)centerImg
{
    // Calculate the size of the generated image and the scale for the desired image size
    CGRect extent = CGRectIntegral(qrImage.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // Since CoreImage nicely interpolates, we need to create a bitmap image that we'll draw into
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 256*4, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    
    // create the context
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:qrImage fromRect:extent];
    
    // draw qrimage
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);

    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    UIImage * qrImg = [UIImage imageWithCGImage:scaledImage];
    
    if (centerImg) {
        CGRect allRc = CGRectMake(0, 0, width, height);
        UIGraphicsBeginImageContext(allRc.size);
        
        [qrImg drawInRect:allRc];
        
        CGFloat centerSz = size/3.3;
        CGRect centerRc = CGRectMake((size - centerSz)/2.0, (size - centerSz)/2.0, centerSz, centerSz);
        [centerImg drawInRect:centerRc];
        
        qrImg = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    
    return qrImg;
}

@end
