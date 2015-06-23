//
//  TurningInfo+Fetcher.h
//  TripMan
//
//  Created by taq on 3/6/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TurningInfo.h"

@interface TurningInfo (Fetcher)

- (NSDictionary*) toJsonDict;
- (NSArray*) turningPts;

@end
