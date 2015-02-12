//
//  BaiduHelper.m
//  TripMan
//
//  Created by taq on 2/11/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaiduHelper.h"

@implementation BaiduHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bdBundle = BDBUNDLE;
    }
    return self;
}

- (UIImage*) imageNamed:(NSString*)filename
{
    if (filename){
        NSString * fullPath = [[self.bdBundle resourcePath] stringByAppendingPathComponent:filename];
        return [UIImage imageWithContentsOfFile:fullPath];
    }
    return nil;
}

@end
