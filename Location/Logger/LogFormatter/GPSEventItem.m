//
//  GPSEventItem.m
//  Location
//
//  Created by taq on 10/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSEventItem.h"

@implementation GPSEventItem

- (id)initWithLogMessage:(DDLogMessage *)logMessage
{
	if ((self = [super init]))
	{
		if (logMessage->logMsg) {
            NSArray * logs = [logMessage->logMsg componentsSeparatedByString:@","];
            if (logs.count == 7) {
                self.eventType = @([logs[0] integerValue]);
                self.latitude = @([logs[1] doubleValue]);
                self.longitude = @([logs[2] doubleValue]);
                self.radius = @([logs[3] doubleValue]);
                self.identifier = logs[4];
                self.groupName = logs[5];
                self.message = logs[6];
            }
        }
		self.timestamp = logMessage->timestamp;
	}
	return self;
}

- (id)initWithDBResultSet:(FMResultSet*)resultSet
{
    if ((self = [super init]))
	{
        self.eventType = [resultSet objectForColumnName:@"eventType"];
		self.latitude = [resultSet objectForColumnName:@"latitude"];
        self.longitude = [resultSet objectForColumnName:@"longitude"];
        self.radius = [resultSet objectForColumnName:@"radius"];
        self.identifier = [resultSet objectForColumnName:@"identifier"];
        self.groupName = [resultSet objectForColumnName:@"groupName"];
        self.message = [resultSet objectForColumnName:@"message"];

		self.timestamp = [resultSet dateForColumn:@"timestamp"];
	}
	return self;
}

- (CLLocation*) location
{
    return [[CLLocation alloc] initWithLatitude:[self.latitude doubleValue] longitude:[self.longitude doubleValue]];
}

- (BOOL) isValidLocation
{
    return ([self.latitude doubleValue] != 0 && [self.longitude doubleValue] != 0);
}

@end
