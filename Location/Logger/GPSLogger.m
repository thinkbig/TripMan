//
//  TSLogger.m
//  tradeshiftHome
//
//  Created by taq on 9/9/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "GPSLogger.h"
#import "GPSFileLogFormatter.h"
#import "DDFileLogger.h"

@interface GPSLogger () {
    
    NSString *      _rootDir;
    NSString *      _tempDir;
    
}

@property (nonatomic, strong) NSDate *                          driveStartDate;
@property (nonatomic, strong) NSDate *                          driveEndDate;

@end

@implementation GPSLogger

+ (instancetype)sharedLogger {
    static GPSLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[self alloc] init];
    });
    
    return _sharedLogger;
}

- (NSString *)logRootDirectory
{
    if (nil == _rootDir) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _rootDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    }
    return _rootDir;
}

- (NSString *)logTempDirectory
{
    if (nil == _tempDir) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _tempDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    }
    return _tempDir;
}

- (NSString *)dbLogRootDirectory
{
    return [[self logRootDirectory] stringByAppendingPathComponent:@"gpsDB"];
    //return [[self logRootDirectory] stringByAppendingPathComponent:@"gpslog"];
}

- (NSString *)fileLogRootDirectory
{
    return [[self logTempDirectory] stringByAppendingPathComponent:@"fileLog"];
}

- (void) renameDir
{
    // 用来修改文件夹名字，最初的命名有问题，可能会被苹果认为是log文件不允许放到document文件夹里面
    // 修改gpslog路径，gpslog改为gpsdb
    NSString * dbLogDir = [self dbLogRootDirectory];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbLogDir isDirectory:&isDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dbLogDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString * dbPath = [dbLogDir stringByAppendingPathComponent:@"gps.sqlite"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath isDirectory:&isDirectory]) {
        NSString * oldDir = [[self logRootDirectory] stringByAppendingPathComponent:@"gpslog"];
        NSString * oldPath = [oldDir stringByAppendingPathComponent:@"gps.sqlite"];
        
        [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:dbPath error:nil];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        [self renameDir];
        
        NSDictionary * lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
        if (lastGoodGPS[@"timestamp"]) {
            if ([[NSDate date] timeIntervalSinceDate:lastGoodGPS[@"timestamp"]] > cOntOfDateThreshold) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMotionIsInTrip];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMotionCurrentStat];
            }
        }

        self.gpsAnalyzer = [[GPSAnalyzerRealTime alloc] init];
        
        self.dbLogger = [[GPSFMDBLogger alloc] initWithLogDirectory:[self dbLogRootDirectory]];

        self.offTimeAnalyzer = [[GPSAnalyzerOffTime alloc] init];
        self.offTimeAnalyzer.dbLogger = self.dbLogger;
    }
    return self;
}

- (DDFileLogger*) fileLogger {
    if (nil == _fileLogger) {
        DDLogFileManagerDefault * manager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:[self fileLogRootDirectory]];
        _fileLogger = [[DDFileLogger alloc] initWithLogFileManager:manager];
        _fileLogger.maximumFileSize = (1024 * 1024 * 8);// 512
        _fileLogger.rollingFrequency = DEFAULT_LOG_ROLLING_FREQUENCY;
        _fileLogger.logFileManager.maximumNumberOfLogFiles = 60;
        _fileLogger.logFileManager.logFilesDiskQuota = (1024 * 1024 * 1024);
    }
    return _fileLogger;
}

-(void) startLogger
{
    [self stopLogger];
    
    // real time analyzer logger
    DDContextWhitelistFilterLogFormatter * wlFormatter = [[DDContextWhitelistFilterLogFormatter alloc] init];
    [wlFormatter addToWhitelist:LogContextGPS];
    [self.gpsAnalyzer setLogFormatter:wlFormatter];
    [DDLog addLogger:self.gpsAnalyzer];
    
    // db logger
    DDContextWhitelistFilterLogFormatter * wlFormatter1 = [[DDContextWhitelistFilterLogFormatter alloc] init];
    [wlFormatter1 addToWhitelist:LogContextGPS];
    [self.dbLogger setLogFormatter:wlFormatter1];
    [DDLog addLogger:self.offTimeAnalyzer.dbLogger];
    
    if ([GToolUtil isEnableDebug]) {
        [self startFileLogger];
    }
}

-(void) stopLogger
{
    [DDLog removeLogger:self.gpsAnalyzer];
    [DDLog removeLogger:self.dbLogger];
}

- (void) startFileLogger
{
    // file logger, log all info, NOT just gps info
    [self stopFileLogger];
    if (self.fileLogger) {
        GPSFileLogFormatter * fileFormatter = [GPSFileLogFormatter new];
        [self.fileLogger setLogFormatter:fileFormatter];
        [DDLog addLogger:self.fileLogger];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kFileLogEnable];
}

- (void) stopFileLogger
{
    [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:kFileLogEnable];
    if (self.fileLogger) {
        [DDLog removeLogger:self.fileLogger];
    }
}

+ (void)load
{
    [[GPSLogger sharedLogger] startLogger];
}


@end
