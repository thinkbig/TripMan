//
//  GPSLogFormatter.m
//  Location
//
//  Created by taq on 9/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSFileLogFormatter.h"
#import "GPSDefine.h"

@interface GPSFileLogFormatter ()

@property (nonatomic, strong) NSDateFormatter *         formatter;

@end

@implementation GPSFileLogFormatter

- (id)init
{
	if ((self = [super init]))
	{
        [super addToWhitelist:LogContextGPS];
	}
	return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	//if ([self isOnWhitelist:logMessage->logContext])
    {
        if (_formatter == nil){
            _formatter = [[NSDateFormatter alloc] init];
            [_formatter setTimeZone:[NSTimeZone localTimeZone]];
            [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        }
        if (logMessage->logFlag == LOG_FLAG_WARN) {
            return [NSString stringWithFormat:@"[%@] %@", [_formatter stringFromDate:logMessage->timestamp], logMessage->logMsg];
        }
    }
    return nil;
}

@end
