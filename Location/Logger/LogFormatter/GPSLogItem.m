//
//  GPSLogItem.m
//  Location
//
//  Created by taq on 9/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSLogItem.h"

@implementation GPSLogItem

- (id)initWithLogMessage:(DDLogMessage *)logMessage
{
	if ((self = [super init]))
	{
		if (logMessage->logMsg) {
            NSArray * logs = [logMessage->logMsg componentsSeparatedByString:@","];
            if (logs.count == 10) {
                self.latitude = @([logs[0] doubleValue]);
                self.longitude = @([logs[1] doubleValue]);
                self.altitude = @([logs[2] doubleValue]);
                self.horizontalAccuracy = @([logs[3] doubleValue]);
                self.verticalAccuracy = @([logs[4] doubleValue]);
                self.course = @([logs[5] doubleValue]);
                self.speed = @([logs[6] doubleValue]);
                self.accelerationX = @([logs[7] doubleValue]);
                self.accelerationY = @([logs[8] doubleValue]);
                self.accelerationZ = @([logs[9] doubleValue]);
                
                self.isValid = YES;
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
		self.latitude = [resultSet objectForColumnName:@"latitude"];
        self.longitude = [resultSet objectForColumnName:@"longitude"];
        self.altitude = [resultSet objectForColumnName:@"altitude"];
        self.horizontalAccuracy = [resultSet objectForColumnName:@"horizontalAccuracy"];
        self.verticalAccuracy = [resultSet objectForColumnName:@"verticalAccuracy"];
        self.course = [resultSet objectForColumnName:@"course"];
        self.speed = [resultSet objectForColumnName:@"speed"];
        self.accelerationX = [resultSet objectForColumnName:@"accelerationX"];
        self.accelerationY = [resultSet objectForColumnName:@"accelerationY"];
        self.accelerationZ = [resultSet objectForColumnName:@"accelerationZ"];
        
        self.isValid = YES;
		self.timestamp = [resultSet dateForColumn:@"timestamp"];
	}
	return self;
}

- (BOOL) isEqual:(GPSLogItem*)object
{
    return [self.latitude floatValue] == [object.latitude floatValue] && [self.longitude floatValue] == [object.longitude floatValue]
        && [self.timestamp isEqualToDate:object.timestamp];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, <%@, %@>, horizontalAccuracy=%@, speed=%@", self.timestamp, self.latitude, self.longitude, self.horizontalAccuracy, self.speed];
}

- (id)initWithEventItem:(GPSEventItem*)event
{
    if ((self = [super init]))
	{
		self.latitude = event.latitude;
        self.longitude = event.longitude;
        
        self.isValid = YES;
	}
	return self;
}

- (id)initWithParkingRegion:(ParkingRegion*)region
{
    if ((self = [super init]))
    {
        self.latitude = region.center_lat;
        self.longitude = region.center_lon;
        
        self.isValid = YES;
    }
    return self;
}

- (id)initWithArray:(NSArray*)arr
{
    if ((self = [super init]))
    {
        if (arr.count >= 11) {
            NSNumber * number = arr[0];
            NSInteger timeStamp = [number integerValue];
            self.timestamp = [NSDate dateWithTimeIntervalSince1970:timeStamp];
            self.latitude = arr[1];
            self.longitude = arr[2];
            self.altitude = arr[3];
            self.horizontalAccuracy = arr[4];
            self.verticalAccuracy = arr[5];
            self.course = arr[6];
            self.speed = arr[7];
            self.accelerationX = arr[8];
            self.accelerationY = arr[9];
            self.accelerationZ = arr[10];
            self.isValid = YES;
        } else {
            self.isValid = NO;
        }
    }
    return self;
}

- (CLLocation*) location
{
    return [[CLLocation alloc] initWithCoordinate:[self coordinate] altitude:[self.altitude doubleValue] horizontalAccuracy:[self.horizontalAccuracy doubleValue] verticalAccuracy:[self.verticalAccuracy doubleValue] course:[self.course doubleValue] speed:[self.speed doubleValue] timestamp:self.timestamp];
}

- (CLLocationCoordinate2D) coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

- (CLLocationDistance) distanceFrom:(GPSLogItem*)item
{
    return [[self location] distanceFromLocation:[item location]];
}

- (CLLocationDistance) distanceFromCLLocation:(CLLocation*)loc
{
    return [[self location] distanceFromLocation:loc];
}

- (CLLocationDistance) distanceFromDict:(NSDictionary*)dict
{
    CLLocation * dictLoc = [[CLLocation alloc] initWithLatitude:[dict[@"lat"] doubleValue] longitude:[dict[@"lon"] doubleValue]];
    if (CLLocationCoordinate2DIsValid(dictLoc.coordinate)) {
        return [dictLoc distanceFromLocation:[self location]];
    }
    return -1;
}

- (double) safeSpeed
{
    return [self.speed doubleValue] > 0 ? [self.speed doubleValue] : 0;
}

- (NSArray*) toArray
{
    return @[@((unsigned long long)[_timestamp timeIntervalSince1970]), _latitude, _longitude, _altitude, _horizontalAccuracy, _verticalAccuracy, _course, _speed, _accelerationX, _accelerationY, _accelerationZ];
}

+ (NSArray *)logArrFromJsonString:(NSString *)jsonStr
{
    NSArray * dictArr = [CommonFacade fromJsonString:jsonStr];
    NSMutableArray * logArr = [NSMutableArray arrayWithCapacity:dictArr.count];
    for (NSArray * itemArr in dictArr) {
        GPSLogItem * item = [[GPSLogItem alloc] initWithArray:itemArr];
        [logArr addObject:item];
    }
    return logArr;
}

@end
