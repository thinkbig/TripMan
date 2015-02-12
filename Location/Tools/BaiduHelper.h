//
//  BaiduHelper.h
//  TripMan
//
//  Created by taq on 2/11/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BDBUNDLE_NAME @ "mapapi.bundle"
#define BDBUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: BDBUNDLE_NAME]
#define BDBUNDLE [NSBundle bundleWithPath: BDBUNDLE_PATH]

@interface BaiduHelper : NSObject

@property (nonatomic, strong) NSBundle *        bdBundle;

- (UIImage*) imageNamed:(NSString*)filename;

@end
