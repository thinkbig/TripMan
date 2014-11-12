//
//  DDLog+CustomTime.m
//  Location
//
//  Created by taq on 10/13/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "DDLog+CustomTime.h"

@interface DDLog ()

+ (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag;

@end

@implementation DDLog (CustomTime)

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(const char *)file
   function:(const char *)function
       line:(int)line
        tag:(id)tag
  timestamp:(NSDate*)timestamp
     format:(NSString *)format, ...
{
    va_list args;
    if (format)
    {
        va_start(args, format);
        
        NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
        DDLogMessage *logMessage = [[DDLogMessage alloc] initWithLogMsg:logMsg
                                                                  level:level
                                                                   flag:flag
                                                                context:context
                                                                   file:file
                                                               function:function
                                                                   line:line
                                                                    tag:tag
                                                                options:0
                                                              timestamp:timestamp];
        
        [self queueLogMessage:logMessage asynchronously:asynchronous];
        
        va_end(args);
    }
}

@end
