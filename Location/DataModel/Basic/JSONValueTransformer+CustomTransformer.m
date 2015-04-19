//
//  JSONValueTransformer+CustomTransformer.m
//  TripMan
//
//  Created by taq on 4/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONValueTransformer+CustomTransformer.h"

@implementation JSONValueTransformer (CustomTransformer)

- (NSNumber *)JSONObjectFromNSDate:(NSDate *)date {
    return @((int)[date timeIntervalSince1970]);
}

@end
