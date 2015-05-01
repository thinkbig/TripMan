#import <Foundation/Foundation.h>
#import "DDAbstractDatabaseLogger.h"
#import "GPSEventItem.h"

@class FMDatabase;


@interface GPSFMDBLogger : DDAbstractDatabaseLogger <DDLogger>
{
@private
	NSString *logDirectory;
	NSMutableArray *pendingLogEntries;
	
	FMDatabase *database;
}

@property (nonatomic, strong, readonly) NSString *                curTableName;
@property (nonatomic) NSInteger                                   maxRowPerTable;         // default < 0 for no limit

/**
 * Initializes an instance set to save it's sqlite file to the given directory.
 * If the directory doesn't already exist, it is automatically created.
**/
- (id)initWithLogDirectory:(NSString *)aLogDirectory;

// api for trips
- (NSArray*)allTripsEvent;

// api for gps logs
- (NSArray*)selectLogFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit;

// api for gps event
- (GPSEventItem*)selectLatestEventBefore:(NSDate*)beforeDate ofType:(eGPSEvent)eventType;
- (GPSEventItem*)selectLatestEventAfter:(NSDate*)afterDate ofType:(eGPSEvent)eventType;
- (GPSEventItem*)selectEvent:(eGPSEvent)eventType between:(NSDate*)fromDate andDate:(NSDate*)toDate;

@end
