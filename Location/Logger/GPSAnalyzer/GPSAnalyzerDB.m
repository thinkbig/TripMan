//
//  GPSAnalyzerDB.m
//  Location
//
//  Created by taq on 9/16/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GPSAnalyzerDB.h"
#import "FMDatabase.h"

@interface GPSAnalyzerDB ()

@property (nonatomic, strong) NSString *        rootDirectory;
@property (nonatomic, strong) FMDatabase *      db;

@end

@implementation GPSAnalyzerDB

- (id)init
{
    if ((self = [super init]))
	{
        [self validateLogDirectory];
		[self openDatabase];
    }
    return self;
}

- (NSString *)rootDirectory
{
    if (nil == _rootDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        _rootDirectory = [baseDir stringByAppendingPathComponent:@"analyze"];
    }
    return _rootDirectory;
}

- (void)dealloc
{
    [_db close];
}

- (void)validateLogDirectory
{
	// Validate log directory exists or create the directory.
	
	BOOL isDirectory;
    NSString * dir = [self rootDirectory];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDirectory]) {
		NSError *error = nil;
		BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:dir
		                                        withIntermediateDirectories:YES
		                                                         attributes:nil
		                                                              error:&error];
		if (!result) {
			NSLog(@"%@: %@ - Unable to create logDirectory(%@) due to error: %@",
				  [self class], THIS_METHOD, dir, error);
		}
	}
}

- (void)openDatabase
{
	NSString *path = [self.rootDirectory stringByAppendingPathComponent:@"analyze.sqlite"];
	
	self.db = [[FMDatabase alloc] initWithPath:path];
	if (![_db open])
	{
		NSLog(@"%@: Failed opening database!", [self class]);
		self.db = nil;
		return;
	}
	
    // db for summary analyze data
	NSString *cmd1 = @"CREATE TABLE IF NOT EXISTS drive_ana \
                        (id INTEGER PRIMARY KEY AUTOINCREMENT, \
                        start_date REAL, \
                        end_date REAL, \
                        total_dist REAL, \
                        total_during REAL, \
                        avg_speed REAL, \
                        max_speed REAL, \
                        traffic_jam_dist REAL, \
                        traffic_jam_during REAL, \
                        is_analyzed INTEGER NOT NULL DEFAULT 0, \
                        desc TEXT)";
	[_db executeUpdate:cmd1];
	if ([_db hadError]) {
		NSLog(@"%@: Error creating drive_ana: code(%d): %@",
			  [self class], [_db lastErrorCode], [_db lastErrorMessage]);
		self.db = nil;
	}
    
    // db for environment analyze data
    NSString *cmd2 = @"CREATE TABLE IF NOT EXISTS env_ana \
                        (trip_id INTEGER PRIMARY KEY, \
                        day_dist REAL, \
                        day_during REAL, \
                        day_avg_speed REAL, \
                        day_max_speed REAL, \
                        night_dist REAL, \
                        night_during REAL, \
                        night_avg_speed REAL, \
                        night_max_speed REAL, \
                        weather TEXT, \
                        temperature TEXT, \
                        moisture TEXT, \
                        wind TEXT, \
                        pm25 REAL, \
                        is_analyzed INTEGER NOT NULL DEFAULT 0)";
    [_db executeUpdate:cmd2];
    if ([_db hadError]) {
        NSLog(@"%@: Error creating env_ana: code(%d): %@",
              [self class], [_db lastErrorCode], [_db lastErrorMessage]);
        self.db = nil;
    }
    
    // db for driving analyze data
    NSString *cmd3 = @"CREATE TABLE IF NOT EXISTS stat_ana \
                        (trip_id INTEGER PRIMARY KEY, \
                        breaking_cnt REAL, \
                        hard_breaking_cnt REAL, \
                        max_breaking_begin_speed REAL, \
                        max_breaking_end_speed REAL, \
                        acce_cnt REAL, \
                        hard_acce_cnt REAL, \
                        max_acce_begin_speed REAL, \
                        max_acce_end_speed REAL, \
                        shortest_40 REAL, \
                        shortest_60 REAL, \
                        shortest_80 REAL, \
                        is_analyzed INTEGER NOT NULL DEFAULT 0)";
    [_db executeUpdate:cmd3];
    if ([_db hadError]) {
        NSLog(@"%@: Error creating stat_ana: code(%d): %@",
              [self class], [_db lastErrorCode], [_db lastErrorMessage]);
        self.db = nil;
    }
    
    // db for turning analyze data
    NSString *cmd4 = @"CREATE TABLE IF NOT EXISTS turning_ana \
                        (trip_id INTEGER PRIMARY KEY, \
                        left_turn_cnt REAL, \
                        left_turn_avg_speed REAL, \
                        left_turn_max_speed REAL, \
                        right_turn_cnt REAL, \
                        right_turn_avg_speed REAL, \
                        right_turn_max_speed REAL, \
                        turn_round_cnt REAL, \
                        turn_round_avg_speed REAL, \
                        turn_round_max_speed REAL, \
                        is_analyzed INTEGER NOT NULL DEFAULT 0)";
    [_db executeUpdate:cmd4];
    if ([_db hadError]) {
        NSLog(@"%@: Error creating turning_ana: code(%d): %@",
              [self class], [_db lastErrorCode], [_db lastErrorMessage]);
        self.db = nil;
    }
    
	[_db setShouldCacheStatements:YES];
}

- (GPSAnalyzeSumItem*)unfinishedTrip
{
    NSLog(@"@@@ %@ = %@", NSStringFromSelector(_cmd), nil);
    GPSAnalyzeSumItem * trip = nil;
    NSString *cmd = @"select id, start_date, end_date from drive_ana ORDER BY id DESC LIMIT 1";
    FMResultSet *rs = [_db executeQuery:cmd];
    while ([rs next]) {
        GPSAnalyzeSumItem * item = [[GPSAnalyzeSumItem alloc] initWithDBResultSet:rs];
        if (nil == item.end_date || [item.end_date isKindOfClass:[NSNull class]]) {
            trip = item;
            break;
        }
    }
    [rs close];
    
    return trip;
}

- (NSArray*)finishedAndUnAnalyzedTrip
{
    NSLog(@"@@@ %@ = %@", NSStringFromSelector(_cmd), nil);
    NSMutableArray * trips = [NSMutableArray array];

    FMResultSet *rs = [_db executeQuery:@"select * from drive_ana where is_analyzed=0 and start_date notnull and end_date notnull"];
    while ([rs next]) {
        GPSAnalyzeSumItem * item = [[GPSAnalyzeSumItem alloc] initWithDBResultSet:rs];
        [trips addObject:item];
    }
    [rs close];
    
    return trips;
}

- (NSArray*)finishedTrip
{
    NSLog(@"@@@ %@ = %@", NSStringFromSelector(_cmd), nil);
    NSMutableArray * trips = [NSMutableArray array];
    
    FMResultSet *rs = [_db executeQuery:@"select * from drive_ana where start_date notnull and end_date notnull"];
    while ([rs next]) {
        GPSAnalyzeSumItem * item = [[GPSAnalyzeSumItem alloc] initWithDBResultSet:rs];
        [trips addObject:item];
    }
    [rs close];
    
    return trips;
}

- (long)beginNewTripAt:(NSDate*)beginDate
{
    NSLog(@"@@@ %@ = %@", NSStringFromSelector(_cmd), beginDate);
    NSString *cmd = @"INSERT INTO drive_ana (start_date, is_analyzed) values(?,0)";
    [_db executeUpdate:cmd, beginDate];
    return (long)[_db lastInsertRowId];
}

- (void)endTrip:(long)tripId atDate:(NSDate*)endDate
{
    NSLog(@"@@@ %@ = %@", NSStringFromSelector(_cmd), endDate);
    if (tripId >= 0 && endDate) {
        NSString * cmd = [NSString stringWithFormat:@"update drive_ana set end_date=? where id=%ld", tripId];
        [_db executeUpdate:cmd, endDate];
    }
}

- (void)updateAnalyzeItem:(GPSAnalyzeSumItem*)item analyzeFinished:(BOOL)isFinished
{
    NSLog(@"@@@ %@ = %@", NSStringFromSelector(_cmd), item);
    NSMutableArray * params = [NSMutableArray arrayWithCapacity:8];
    NSMutableString * cmd = [NSMutableString stringWithString:@"update drive_ana set"];
    if (item.start_date) {
        [cmd appendString:@" start_date=?"];
        [params addObject:item.start_date];
    }
    if (item.end_date) {
        [cmd appendString:@", end_date=?"];
        [params addObject:item.end_date];
    }
    if (item.total_dist) {
        [cmd appendString:@", total_dist=?"];
        [params addObject:item.total_dist];
    }
    if (item.total_during) {
        [cmd appendString:@", total_during=?"];
        [params addObject:item.total_during];
    }
    if (item.avg_speed) {
        [cmd appendString:@", avg_speed=?"];
        [params addObject:item.avg_speed];
    }
    if (item.max_speed) {
        [cmd appendString:@", max_speed=?"];
        [params addObject:item.max_speed];
    }
    if (item.traffic_jam_dist) {
        [cmd appendString:@", traffic_jam_dist=?"];
        [params addObject:item.traffic_jam_dist];
    }
    if (item.traffic_jam_during) {
        [cmd appendString:@", traffic_jam_during=?"];
        [params addObject:item.traffic_jam_during];
    }
    if (item.desc) {
        [cmd appendString:@", desc=?"];
        [params addObject:item.desc];
    }
    [cmd appendString:@", is_analyzed=?"];
    [params addObject:@(isFinished)];
    
    [cmd appendFormat:@" where id=%ld", item.db_id];
    
    [_db executeUpdate:cmd withArgumentsInArray:params];
}

- (AnalyzeEnvItem*)analyzedEnvItemForId:(long)tripId
{
    AnalyzeEnvItem * item = nil;
    NSString * cmd = [NSString stringWithFormat:@"select * from env_ana where trip_id=%ld", tripId];
    FMResultSet *rs = [_db executeQuery:cmd];
    while ([rs next]) {
        item = [[AnalyzeEnvItem alloc] initWithDBResultSet:rs];
    }
    [rs close];
    
    return item;
}

- (void)updateEnvItem:(AnalyzeEnvItem*)item analyzeFinished:(BOOL)isFinished
{
    NSString * checkCmd = [NSString stringWithFormat:@"INSERT OR IGNORE INTO env_ana (trip_id, is_analyzed) VALUES (%ld, 0)", item.db_id];
    [_db executeUpdate:checkCmd];
    
    NSMutableArray * params = [NSMutableArray arrayWithCapacity:8];
    NSMutableString * cmd = [NSMutableString stringWithString:@"update env_ana set"];
    if (item.day_dist) {
        [cmd appendString:@" day_dist=?"];
        [params addObject:item.day_dist];
    }
    if (item.day_during) {
        [cmd appendString:@", day_during=?"];
        [params addObject:item.day_during];
    }
    if (item.day_avg_speed) {
        [cmd appendString:@", day_avg_speed=?"];
        [params addObject:item.day_avg_speed];
    }
    if (item.day_max_speed) {
        [cmd appendString:@", day_max_speed=?"];
        [params addObject:item.day_max_speed];
    }
    if (item.night_dist) {
        [cmd appendString:@", night_dist=?"];
        [params addObject:item.night_dist];
    }
    if (item.night_during) {
        [cmd appendString:@", night_during=?"];
        [params addObject:item.night_during];
    }
    if (item.night_avg_speed) {
        [cmd appendString:@", night_avg_speed=?"];
        [params addObject:item.night_avg_speed];
    }
    if (item.night_max_speed) {
        [cmd appendString:@", night_max_speed=?"];
        [params addObject:item.night_max_speed];
    }
    if (item.weather) {
        [cmd appendString:@", weather=?"];
        [params addObject:item.weather];
    }
    if (item.temperature) {
        [cmd appendString:@", temperature=?"];
        [params addObject:item.temperature];
    }
    if (item.moisture) {
        [cmd appendString:@", moisture=?"];
        [params addObject:item.moisture];
    }
    if (item.wind) {
        [cmd appendString:@", wind=?"];
        [params addObject:item.wind];
    }
    if (item.pm25) {
        [cmd appendString:@", pm25=?"];
        [params addObject:item.pm25];
    }
    [cmd appendString:@", is_analyzed=?"];
    [params addObject:@(isFinished)];
    
    [cmd appendFormat:@" where trip_id=%ld", item.db_id];
    
    [_db executeUpdate:cmd withArgumentsInArray:params];
}

- (AnalyzeDrivingItem*)analyzedDrivingItemForId:(long)tripId
{
    AnalyzeDrivingItem * item = nil;
    NSString * cmd = [NSString stringWithFormat:@"select * from stat_ana where trip_id=%ld", tripId];
    FMResultSet *rs = [_db executeQuery:cmd];
    while ([rs next]) {
        item = [[AnalyzeDrivingItem alloc] initWithDBResultSet:rs];
    }
    [rs close];
    
    return item;
}

- (void)updateDrivingItem:(AnalyzeDrivingItem*)item analyzeFinished:(BOOL)isFinished
{
    NSString * checkCmd = [NSString stringWithFormat:@"INSERT OR IGNORE INTO stat_ana (trip_id, is_analyzed) VALUES (%ld, 0)", item.db_id];
    [_db executeUpdate:checkCmd];
    
    NSMutableArray * params = [NSMutableArray arrayWithCapacity:8];
    NSMutableString * cmd = [NSMutableString stringWithString:@"update stat_ana set"];
    if (item.breaking_cnt) {
        [cmd appendString:@" breaking_cnt=?"];
        [params addObject:item.breaking_cnt];
    }
    if (item.hard_breaking_cnt) {
        [cmd appendString:@", hard_breaking_cnt=?"];
        [params addObject:item.hard_breaking_cnt];
    }
    if (item.max_breaking_begin_speed) {
        [cmd appendString:@", max_breaking_begin_speed=?"];
        [params addObject:item.max_breaking_begin_speed];
    }
    if (item.max_breaking_end_speed) {
        [cmd appendString:@", max_breaking_end_speed=?"];
        [params addObject:item.max_breaking_end_speed];
    }
    if (item.acce_cnt) {
        [cmd appendString:@", acce_cnt=?"];
        [params addObject:item.acce_cnt];
    }
    if (item.hard_acce_cnt) {
        [cmd appendString:@", hard_acce_cnt=?"];
        [params addObject:item.hard_acce_cnt];
    }
    if (item.max_acce_begin_speed) {
        [cmd appendString:@", max_acce_begin_speed=?"];
        [params addObject:item.max_acce_begin_speed];
    }
    if (item.max_acce_end_speed) {
        [cmd appendString:@", max_acce_end_speed=?"];
        [params addObject:item.max_acce_end_speed];
    }
    if (item.shortest_40) {
        [cmd appendString:@", shortest_40=?"];
        [params addObject:item.shortest_40];
    }
    if (item.shortest_60) {
        [cmd appendString:@", shortest_60=?"];
        [params addObject:item.shortest_60];
    }
    if (item.shortest_80) {
        [cmd appendString:@", shortest_80=?"];
        [params addObject:item.shortest_80];
    }
    [cmd appendString:@", is_analyzed=?"];
    [params addObject:@(isFinished)];
    
    [cmd appendFormat:@" where trip_id=%ld", item.db_id];
    
    [_db executeUpdate:cmd withArgumentsInArray:params];
}

- (AnalyzeTurningItem*)analyzedTurningItemForId:(long)tripId
{
    AnalyzeTurningItem * item = nil;
    NSString * cmd = [NSString stringWithFormat:@"select * from turning_ana where trip_id=%ld", tripId];
    FMResultSet *rs = [_db executeQuery:cmd];
    while ([rs next]) {
        item = [[AnalyzeTurningItem alloc] initWithDBResultSet:rs];
    }
    [rs close];
    
    return item;
}

- (void)updateTurningItem:(AnalyzeTurningItem*)item analyzeFinished:(BOOL)isFinished
{
    NSString * checkCmd = [NSString stringWithFormat:@"INSERT OR IGNORE INTO turning_ana (trip_id, is_analyzed) VALUES (%ld, 0)", item.db_id];
    [_db executeUpdate:checkCmd];
    
    NSMutableArray * params = [NSMutableArray arrayWithCapacity:8];
    NSMutableString * cmd = [NSMutableString stringWithString:@"update turning_ana set"];
    if (item.left_turn_cnt) {
        [cmd appendString:@" left_turn_cnt=?"];
        [params addObject:item.left_turn_cnt];
    }
    if (item.left_turn_avg_speed) {
        [cmd appendString:@", left_turn_avg_speed=?"];
        [params addObject:item.left_turn_avg_speed];
    }
    if (item.left_turn_max_speed) {
        [cmd appendString:@", left_turn_max_speed=?"];
        [params addObject:item.left_turn_max_speed];
    }
    if (item.right_turn_cnt) {
        [cmd appendString:@", right_turn_cnt=?"];
        [params addObject:item.right_turn_cnt];
    }
    if (item.right_turn_avg_speed) {
        [cmd appendString:@", right_turn_avg_speed=?"];
        [params addObject:item.right_turn_avg_speed];
    }
    if (item.right_turn_max_speed) {
        [cmd appendString:@", right_turn_max_speed=?"];
        [params addObject:item.right_turn_max_speed];
    }
    if (item.turn_round_cnt) {
        [cmd appendString:@", turn_round_cnt=?"];
        [params addObject:item.turn_round_cnt];
    }
    if (item.turn_round_avg_speed) {
        [cmd appendString:@", turn_round_avg_speed=?"];
        [params addObject:item.turn_round_avg_speed];
    }
    if (item.turn_round_max_speed) {
        [cmd appendString:@", turn_round_max_speed=?"];
        [params addObject:item.turn_round_max_speed];
    }
    [cmd appendString:@", is_analyzed=?"];
    [params addObject:@(isFinished)];
    
    [cmd appendFormat:@" where trip_id=%ld", item.db_id];
    
    [_db executeUpdate:cmd withArgumentsInArray:params];
}

- (GPSAnalyzeSumItem*)lastAnalyzedResult
{
    GPSAnalyzeSumItem * item = nil;
    NSString *cmd = @"select * from drive_ana where is_analyzed=1 order by id desc limit 1";
    FMResultSet *rs = [_db executeQuery:cmd];
    while ([rs next]) {
        item = [[GPSAnalyzeSumItem alloc] initWithDBResultSet:rs];
    }
    [rs close];
    
    return item;
}

- (NSArray*)analyzedResultFrom:(NSDate*)fromDate toDate:(NSDate*)toDate offset:(NSInteger)offset limit:(NSInteger)limit reverseOrder:(BOOL)reverse
{
    NSMutableString * cmd = [NSMutableString stringWithString:@"select * from drive_ana where is_analyzed=1"];
    if (fromDate) {
        [cmd appendString:@" and start_date >= ?"];
    }
    if (toDate) {
        [cmd appendString:@" and end_date <= ?"];
    }
    if (reverse) {
        [cmd appendString:@" order by id desc"];
    } else {
        [cmd appendString:@" order by id asc"];
    }
    if (offset >= 0 && limit > 0) {
        [cmd appendFormat:@" limit %ld,%ld", (long)offset, (long)limit];
    }

    NSMutableArray * allData = [NSMutableArray arrayWithCapacity:8];
    
    FMResultSet *rs = [_db executeQuery:cmd];
    while ([rs next]) {
        GPSAnalyzeSumItem * item = [[GPSAnalyzeSumItem alloc] initWithDBResultSet:rs];
        [allData addObject:item];
    }
    [rs close];
    
    return allData;
}

@end
