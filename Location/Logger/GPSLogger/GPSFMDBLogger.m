
#import "GPSFMDBLogger.h"
#import "FMDatabase.h"
#import "DDContextFilterLogFormatter.h"
#import "GPSLogItem.h"
#import "NSDate+Utilities.h"

@interface GPSFMDBLogger () {
    
    NSDateFormatter *           _tablenameFormatter;
    
}

- (void)validateLogDirectory;
- (void)openDatabase;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation GPSFMDBLogger

@synthesize curTableName = _curTableName;

- (id)initWithLogDirectory:(NSString *)aLogDirectory
{
    if ((self = [super init]))
	{
        self.maxAge = -1;
        self.deleteInterval = -1;
        self.deleteOnEverySave = NO;
        
		logDirectory = [aLogDirectory copy];
        _curTableName = nil;
        _tablenameFormatter = [[NSDateFormatter alloc] init];
        [_tablenameFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [_tablenameFormatter setDateFormat:@"yyyyMMddHHmmss"];
		
		pendingLogEntries = [[NSMutableArray alloc] initWithCapacity:16];
		
		[self validateLogDirectory];
		[self openDatabase];
        [self updateCurrentTable];
    }
    
    return self;
}

- (void)dealloc
{
    [dbQueue close];
}

- (NSArray*)allTripsEvent
{
    NSMutableArray * trips = [NSMutableArray array];
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"select * from gps_event where eventType in (1000, 1001, 1002, 300, 301, 302) order by timestamp asc"];
        while ([rs next]) {
            GPSEventItem * item = [[GPSEventItem alloc] initWithDBResultSet:rs];
            [trips addObject:item];
        }
        [rs close];
    }];

    return trips;
}

- (NSArray*)selectLogFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit
{
    NSMutableArray * tables = [NSMutableArray array];
    CGFloat from = fromDate ? [fromDate timeIntervalSince1970] : 0;
    CGFloat to = toDate ? [toDate timeIntervalSince1970] : MAXFLOAT;
    
    NSString * cmd = [NSString stringWithFormat:@"select table_name from logidx where is_valid = 1 AND is_active = 1 order by id asc"];
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:cmd];
        while ([rs next]) {
            [tables addObject:[rs objectForColumnName:@"table_name"]];
        }
        [rs close];
    }];
    
    // @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 这里为了方便起见，假设不分表 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    NSString * tableName = [tables lastObject];
    if (nil == tableName) {
        return nil;
    }
    
    NSMutableArray * allData = [NSMutableArray arrayWithCapacity:limit];
    NSMutableString * cmd1 = [NSMutableString stringWithFormat:@"select * from %@ where timestamp between %f and %f", tableName, from, to];
    if (offset >= 0 && limit > 0) {
        [cmd1 appendFormat:@" limit %ld,%ld", (long)offset, (long)limit];
    }
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs1 = [db executeQuery:cmd1];
        while ([rs1 next]) {
            GPSLogItem * item = [[GPSLogItem alloc] initWithDBResultSet:rs1];
            [allData addObject:item];
        }
        [rs1 close];
    }];
    
    return allData;
}

- (GPSEventItem*)selectLatestEventBefore:(NSDate*)beforeDate ofType:(eGPSEvent)eventType
{
    if (nil == beforeDate) {
        beforeDate = [NSDate distantFuture];
    }
    __block GPSEventItem * item = nil;
    NSMutableString * cmd = nil;
    if (eGPSEventMonitorRegion == eventType) {
        cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp <= %f and eventType = %d and (groupName = '%@' or groupName = '%@') order by timestamp desc limit 1", [beforeDate timeIntervalSince1970], (int)eventType, REGION_GROUP_LAST_STILL, REGION_GROUP_LAST_PARKING];
    } else {
        cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp <= %f and eventType = %d order by timestamp desc limit 1", [beforeDate timeIntervalSince1970], (int)eventType];
    }
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs1 = [db executeQuery:cmd];
        while ([rs1 next]) {
            item = [[GPSEventItem alloc] initWithDBResultSet:rs1];
            break;
        }
        [rs1 close];
    }];
    
    
    return item;
}

- (GPSEventItem*)selectEvent:(eGPSEvent)eventType between:(NSDate*)fromDate andDate:(NSDate*)toDate
{
    if (nil == toDate || nil == fromDate || [toDate isEarlierThanDate:fromDate]) {
        return nil;
    }

    __block GPSEventItem * item = nil;
    NSMutableString * cmd = nil;
    if (eGPSEventMonitorRegion == eventType) {
        cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp >= %f and timestamp <= %f and eventType = %d and (groupName = '%@' or groupName = '%@') order by timestamp desc limit 1", [fromDate timeIntervalSince1970], [toDate timeIntervalSince1970], (int)eventType, REGION_GROUP_LAST_STILL, REGION_GROUP_LAST_PARKING];
    } else {
        cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp >= %f and timestamp <= %f and eventType = %d order by timestamp desc limit 1", [fromDate timeIntervalSince1970], [toDate timeIntervalSince1970], (int)eventType];
    }
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs1 = [db executeQuery:cmd];
        while ([rs1 next]) {
            item = [[GPSEventItem alloc] initWithDBResultSet:rs1];
            break;
        }
        [rs1 close];
    }];
    
    return item;
}

- (GPSEventItem*)selectLatestEventAfter:(NSDate*)afterDate ofType:(eGPSEvent)eventType
{
    if (nil == afterDate) {
        afterDate = [NSDate date];
    }
    __block GPSEventItem * item = nil;
    NSMutableString * cmd = nil;
    if (eGPSEventMonitorRegion == eventType) {
        cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp >= %f and eventType = %d and (groupName = '%@' or groupName = '%@') order by timestamp asc limit 1", [afterDate timeIntervalSince1970], (int)eventType, REGION_GROUP_LAST_STILL, REGION_GROUP_LAST_PARKING];
    } else {
        cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp >= %f and eventType = %d order by timestamp asc limit 1", [afterDate timeIntervalSince1970], (int)eventType];
    }
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs1 = [db executeQuery:cmd];
        while ([rs1 next]) {
            item = [[GPSEventItem alloc] initWithDBResultSet:rs1];
            break;
        }
        [rs1 close];
    }];
    
    return item;
}


- (void)validateLogDirectory
{
	// Validate log directory exists or create the directory.
	
	BOOL isDirectory;
	if ([[NSFileManager defaultManager] fileExistsAtPath:logDirectory isDirectory:&isDirectory])
	{
		if (!isDirectory)
		{
			NSLog(@"%@: %@ - logDirectory(%@) is a file!", [self class], THIS_METHOD, logDirectory);
			logDirectory = nil;
		}
	}
	else
	{
		NSError *error = nil;
		
		BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory
		                                        withIntermediateDirectories:YES
		                                                         attributes:nil
		                                                              error:&error];
		if (!result)
		{
			NSLog(@"%@: %@ - Unable to create logDirectory(%@) due to error: %@",
				  [self class], THIS_METHOD, logDirectory, error);
			logDirectory = nil;
		}
	}
}

- (void)openDatabase
{
	if (logDirectory == nil)
	{
		return;
	}
	
	NSString *path = [logDirectory stringByAppendingPathComponent:@"gps.sqlite"];
	
	dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];

    // create log index db
	NSString *cmd1 = @"CREATE TABLE IF NOT EXISTS logidx \
                        (id INTEGER PRIMARY KEY AUTOINCREMENT, \
                        table_name TEXT NOT NULL UNIQUE, \
                        begin_date REAL, \
                        end_date REAL, \
                        is_valid INTEGER NOT NULL DEFAULT 1, \
                        is_active INTEGER NOT NULL DEFAULT 0, \
                        desc TEXT)";
    [dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:cmd1];
    }];

    // create gps event db
    NSString *cmd2 = @"CREATE TABLE IF NOT EXISTS gps_event \
                        (id INTEGER PRIMARY KEY AUTOINCREMENT, \
                        timestamp REAL NOT NULL DEFAULT 0, \
                        eventType INTEGER NOT NULL DEFAULT 0, \
                        latitude REAL, \
                        longitude REAL, \
                        radius REAL, \
                        identifier TEXT, \
                        groupName TEXT, \
                        message TEXT)";
    [dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:cmd2];
    }];    
}

- (void) updateCurrentTable
{
    // update current table name
    __block NSString * tableName = nil;
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT table_name from logidx where is_valid=1 and is_active=1"];
        while ([rs next]) {
            tableName = [rs objectForColumnName:@"table_name"];
            break;
        }
        [rs close];
    }];
    
    if (nil == tableName) {
        tableName = [self nonreqeatTablename];
        NSString *cmd = @"INSERT INTO logidx (table_name, is_valid, is_active) values(?,1,1)";
        [dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:cmd, tableName];
        }];
    }
    
    // update current table
    NSString *cmd1 = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ \
                      (id INTEGER PRIMARY KEY AUTOINCREMENT, \
                      timestamp REAL NOT NULL, \
                      latitude REAL, \
                      longitude REAL, \
                      altitude REAL, \
                      horizontalAccuracy REAL, \
                      verticalAccuracy REAL, \
                      course REAL, \
                      speed REAL, \
                      accelerationX REAL, \
                      accelerationY REAL, \
                      accelerationZ REAL)",
                      tableName];
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:cmd1];
    }];
    
    NSString *cmd2 = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS timestamp ON %@ (timestamp)", tableName];
    [dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:cmd2];
    }];
    
    _curTableName = tableName;
}

- (NSString*) nonreqeatTablename
{
    return [NSString stringWithFormat:@"gpslog_%@", [_tablenameFormatter stringFromDate:[NSDate date]]];
}

- (NSString*) curTableName
{
    if (nil == _curTableName) {
        [self updateCurrentTable];
    }
    return _curTableName;
}


#pragma mark AbstractDatabaseLogger Overrides

- (BOOL)db_log:(DDLogMessage *)logMessage
{
	// You may be wondering, how come we don't just do the insert here and be done with it?
	// Is the buffering really needed?
	// 
	// From the SQLite FAQ:
	// 
	// (19) INSERT is really slow - I can only do few dozen INSERTs per second
	// 
	// Actually, SQLite will easily do 50,000 or more INSERT statements per second on an average desktop computer.
	// But it will only do a few dozen transactions per second. Transaction speed is limited by the rotational
	// speed of your disk drive. A transaction normally requires two complete rotations of the disk platter, which
	// on a 7200RPM disk drive limits you to about 60 transactions per second.
	// 
	// Transaction speed is limited by disk drive speed because (by default) SQLite actually waits until the data
	// really is safely stored on the disk surface before the transaction is complete. That way, if you suddenly
	// lose power or if your OS crashes, your data is still safe. For details, read about atomic commit in SQLite.
	// 
	// By default, each INSERT statement is its own transaction. But if you surround multiple INSERT statements
	// with BEGIN...COMMIT then all the inserts are grouped into a single transaction. The time needed to commit
	// the transaction is amortized over all the enclosed insert statements and so the time per insert statement
	// is greatly reduced.
	
    if ([formatter isKindOfClass:[DDContextWhitelistFilterLogFormatter class]]) {
        DDContextWhitelistFilterLogFormatter * whiteFilter = (DDContextWhitelistFilterLogFormatter*)formatter;
        if (![whiteFilter isOnWhitelist:logMessage->logContext]) {
            return NO;
        }  
    }
    
    switch (logMessage->logFlag) {
        case LOG_FLAG_GPS_DATA:
        {
            GPSLogItem *logEntry = [[GPSLogItem alloc] initWithLogMessage:logMessage];
            [pendingLogEntries addObject:logEntry];
            break;
        }
        case LOG_FLAG_GPS_EVENT:
        {
            GPSEventItem *logEntry = [[GPSEventItem alloc] initWithLogMessage:logMessage];
            [pendingLogEntries addObject:logEntry];
            break;
        }
            
        default:
            break;
    }
	
	// Return YES if an item was added to the buffer.
	// Return NO if the logMessage was ignored.
	
	return YES;
}

- (void)db_save
{
	if ([pendingLogEntries count] == 0)
	{
		// Nothing to save.
		// The superclass won't likely call us if this is the case, but we're being cautious.
		return;
	}
    
    NSArray * tmpArr = [pendingLogEntries copy];
    [pendingLogEntries removeAllObjects];
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        for (id logEntry in tmpArr)
        {
            if ([logEntry isKindOfClass:[GPSLogItem class]]) {
                GPSLogItem * gpsItem = (GPSLogItem*)logEntry;
                NSString * tableName = self.curTableName;
                if (tableName) {
                    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO %@ (timestamp, latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy, course, speed, accelerationX, accelerationY, accelerationZ) VALUES (?,?,?,?,?,?,?,?,?,?,?)", tableName];
                    [db executeUpdate:cmd, gpsItem.timestamp, gpsItem.latitude, gpsItem.longitude, gpsItem.altitude, gpsItem.horizontalAccuracy, gpsItem.verticalAccuracy, gpsItem.course, gpsItem.speed, gpsItem.accelerationX, gpsItem.accelerationY, gpsItem.accelerationZ];
                }
            } else if ([logEntry isKindOfClass:[GPSEventItem class]]) {
                GPSEventItem * eventItem = (GPSEventItem*)logEntry;
                NSString *cmd = @"INSERT INTO gps_event (timestamp, eventType, latitude, longitude, radius, identifier, groupName, message) VALUES (?,?,?,?,?,?,?,?)";
                [db executeUpdate:cmd, eventItem.timestamp, eventItem.eventType, eventItem.latitude, eventItem.longitude, eventItem.radius, eventItem.identifier, eventItem.groupName, eventItem.message];
            }
        }
    }];
}

- (void)db_delete
{
	if (maxAge <= 0.0)
	{
		// Deleting old log entries is disabled.
		// The superclass won't likely call us if this is the case, but we're being cautious.
		return;
	}
    
    // todo
	
//	BOOL deleteOnlyTransaction = ![database inTransaction];
//	
//	NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:(-1.0 * maxAge)];
//	
//	[database executeUpdate:@"DELETE FROM logs WHERE timestamp < ?", maxDate];
//	
//	if (deleteOnlyTransaction)
//	{
//		if ([database hadError])
//		{
//			NSLog(@"%@: Error deleting log entries: code(%d): %@",
//				  [self class], [database lastErrorCode], [database lastErrorMessage]);
//		}
//	}
}

- (void)db_saveAndDelete
{
	[self db_delete];
	[self db_save];

}

@end
