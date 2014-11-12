
#import "GPSFMDBLogger.h"
#import "FMDatabase.h"
#import "DDContextFilterLogFormatter.h"
#import "GPSLogItem.h"

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
    [database close];
}

- (NSArray*)allTripsEvent
{
    NSMutableArray * trips = [NSMutableArray array];
    FMResultSet *rs = [database executeQuery:@"select * from gps_event where eventType between 1000 and 1001 order by timestamp asc"];
    while ([rs next]) {
        GPSEventItem * item = [[GPSEventItem alloc] initWithDBResultSet:rs];
        [trips addObject:item];
    }
    [rs close];
    
    return trips;
}

- (NSArray*)selectLogFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit
{
    NSMutableArray * tables = [NSMutableArray array];
    CGFloat from = fromDate ? [fromDate timeIntervalSince1970] : 0;
    CGFloat to = toDate ? [toDate timeIntervalSince1970] : MAXFLOAT;
    
    //NSString * cmd = [NSString stringWithFormat:@"select table_name from logidx where (end_date > %f OR end_date = NULL) AND begin_date < %f order by id asc", from, to];
    NSString * cmd = [NSString stringWithFormat:@"select table_name from logidx where is_valid = 1 AND is_active = 1 order by id asc"];
    FMResultSet *rs = [database executeQuery:cmd];
    while ([rs next]) {
        [tables addObject:[rs objectForColumnName:@"table_name"]];
    }
    [rs close];
    
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
    FMResultSet *rs1 = [database executeQuery:cmd1];
    while ([rs1 next]) {
        GPSLogItem * item = [[GPSLogItem alloc] initWithDBResultSet:rs1];
        [allData addObject:item];
    }
    [rs1 close];
    
    return allData;
}

- (GPSEventItem*)selectLatestEventBefore:(NSDate*)beforeDate ofType:(eGPSEvent)eventType
{
    if (nil == beforeDate) {
        beforeDate = [NSDate distantFuture];
    }
    GPSEventItem * item = nil;
    NSMutableString * cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp <= %f and eventType = %d order by timestamp desc limit 1", [beforeDate timeIntervalSince1970], (int)eventType];
    FMResultSet *rs1 = [database executeQuery:cmd];
    while ([rs1 next]) {
        item = [[GPSEventItem alloc] initWithDBResultSet:rs1];
        break;
    }
    [rs1 close];
    
    return item;
}

- (GPSEventItem*)selectLatestEventAfter:(NSDate*)afterDate ofType:(eGPSEvent)eventType
{
    if (nil == afterDate) {
        afterDate = [NSDate date];
    }
    GPSEventItem * item = nil;
    NSMutableString * cmd = [NSMutableString stringWithFormat:@"select * from gps_event where timestamp >= %f and eventType = %d order by timestamp asc limit 1", [afterDate timeIntervalSince1970], (int)eventType];
    FMResultSet *rs1 = [database executeQuery:cmd];
    while ([rs1 next]) {
        item = [[GPSEventItem alloc] initWithDBResultSet:rs1];
        break;
    }
    [rs1 close];
    
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
	
	database = [[FMDatabase alloc] initWithPath:path];
	
	if (![database open])
	{
		NSLog(@"%@: Failed opening database!", [self class]);
		database = nil;
		return;
	}
	
    // create log index db
	NSString *cmd1 = @"CREATE TABLE IF NOT EXISTS logidx \
                        (id INTEGER PRIMARY KEY AUTOINCREMENT, \
                        table_name TEXT NOT NULL UNIQUE, \
                        begin_date REAL, \
                        end_date REAL, \
                        is_valid INTEGER NOT NULL DEFAULT 1, \
                        is_active INTEGER NOT NULL DEFAULT 0, \
                        desc TEXT)";
	[database executeUpdate:cmd1];
	if ([database hadError])
	{
		NSLog(@"%@: Error creating table logidx: code(%d): %@",
			  [self class], [database lastErrorCode], [database lastErrorMessage]);
		database = nil;
	}

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
	[database executeUpdate:cmd2];
	if ([database hadError])
	{
		NSLog(@"%@: Error creating table gps_event: code(%d): %@",
			  [self class], [database lastErrorCode], [database lastErrorMessage]);
		database = nil;
	}
    
	[database setShouldCacheStatements:YES];
}

- (void) updateCurrentTable
{
    // update current table name
    NSString * tableName = nil;
    FMResultSet *rs = [database executeQuery:@"SELECT table_name from logidx where is_valid=1 and is_active=1"];
    while ([rs next]) {
        tableName = [rs objectForColumnName:@"table_name"];
        break;
    }
    [rs close];
    
    if (nil == tableName) {
        tableName = [self nonreqeatTablename];
        NSString *cmd = @"INSERT INTO logidx (table_name, is_valid, is_active) values(?,1,1)";
        [database executeUpdate:cmd, tableName];
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
    
    [database executeUpdate:cmd1];
    if ([database hadError])
    {
        NSLog(@"%@: Error creating table: %d: %@",
              tableName, [database lastErrorCode], [database lastErrorMessage]);
        return;
    }
    
    NSString *cmd2 = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS timestamp ON %@ (timestamp)", tableName];
    
    [database executeUpdate:cmd2];
    if ([database hadError])
    {
        NSLog(@"%@: Error creating index: %d: %@",
              tableName, [database lastErrorCode], [database lastErrorMessage]);
        return;
    }
    
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
	
	BOOL saveOnlyTransaction = ![database inTransaction];
	
	if (saveOnlyTransaction)
	{
		[database beginTransaction];
	}
    
    for (id logEntry in pendingLogEntries)
    {
        if ([logEntry isKindOfClass:[GPSLogItem class]]) {
            GPSLogItem * gpsItem = (GPSLogItem*)logEntry;
            NSString * tableName = self.curTableName;
            if (tableName) {
                NSString *cmd = [NSString stringWithFormat:@"INSERT INTO %@ (timestamp, latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy, course, speed, accelerationX, accelerationY, accelerationZ) VALUES (?,?,?,?,?,?,?,?,?,?,?)", tableName];
                [database executeUpdate:cmd, gpsItem.timestamp, gpsItem.latitude, gpsItem.longitude, gpsItem.altitude, gpsItem.horizontalAccuracy, gpsItem.verticalAccuracy, gpsItem.course, gpsItem.speed, gpsItem.accelerationX, gpsItem.accelerationY, gpsItem.accelerationZ];
            }
        } else if ([logEntry isKindOfClass:[GPSEventItem class]]) {
            GPSEventItem * eventItem = (GPSEventItem*)logEntry;
            NSString *cmd = @"INSERT INTO gps_event (timestamp, eventType, latitude, longitude, radius, identifier, groupName, message) VALUES (?,?,?,?,?,?,?,?)";
            [database executeUpdate:cmd, eventItem.timestamp, eventItem.eventType, eventItem.latitude, eventItem.longitude, eventItem.radius, eventItem.identifier, eventItem.groupName, eventItem.message];
        }
    }
	
	[pendingLogEntries removeAllObjects];
	
	if (saveOnlyTransaction)
	{
		[database commit];
		
		if ([database hadError])
		{
			NSLog(@"%@: Error inserting log entries: code(%d): %@",
				  [self class], [database lastErrorCode], [database lastErrorMessage]);
		}
	}
}

- (void)db_delete
{
	if (_maxAge <= 0.0)
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
	[database beginTransaction];
	
	[self db_delete];
	[self db_save];
	
	[database commit];
	
	if ([database hadError])
	{
		NSLog(@"%@: Error: code(%d): %@",
			  [self class], [database lastErrorCode], [database lastErrorMessage]);
	}
}

@end
