//
//  JamZone.m
//  TripMan
//
//  Created by taq on 4/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JamZone.h"

@implementation JamZone

- (CGFloat) headingDegree
{
    NSArray * headings = [self.direction componentsSeparatedByString:@","];
    if (headings.count > 0) {
        return [headings[0] floatValue];
    }
    return 0;
}

@end
