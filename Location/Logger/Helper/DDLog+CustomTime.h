//
//  DDLog+CustomTime.h
//  Location
//
//  Created by taq on 10/13/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "DDLog.h"

@interface DDLog (CustomTime)

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(const char *)file
   function:(const char *)function
       line:(int)line
        tag:(id)tag
  timestamp:(NSDate*)timestamp
     format:(NSString *)format, ...;

@end
