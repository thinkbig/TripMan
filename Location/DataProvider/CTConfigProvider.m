//
//  CTConfigProvider.m
//  TripMan
//
//  Created by taq on 5/14/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTConfigProvider.h"

#define kServerConfigKey            @"kServerConfigKey"

@interface CTConfigProvider ()

@property (nonatomic, strong) NSMutableDictionary *     realServerConfig;
@property (nonatomic, strong) NSString *                currentServerName;

@end

@implementation CTConfigProvider

static CTConfigProvider * _sharedInst = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInst = [[CTConfigProvider alloc] init];
    });
    return _sharedInst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadServerConfig];
    }
    return self;
}

- (void) loadServerConfig
{
    if (nil == self.realServerConfig) {
        NSDictionary * config = [[NSUserDefaults standardUserDefaults] objectForKey:kServerConfigKey];
        NSInteger thisVersionCnt = 4;
        if (nil == config || config.count != thisVersionCnt) {
            config = @{@"Production": @{@"url": @"http://115.29.200.94:80/", @"isSelect": @YES},
                       @"Linux(主)": @{@"url": @"http://115.29.200.94:9000/", @"isSelect": @NO},
                       @"Linux(从)": @{@"url": @"http://218.244.139.25:9000/", @"isSelect": @NO},
                       @"Windows(废)": @{@"url": @"http://121.40.193.34:80/", @"isSelect": @NO}
                       };
        }
        
        self.realServerConfig = [config mutableCopy];
    }
    [self.realServerConfig enumerateKeysAndObjectsUsingBlock:^(id key, id dict, BOOL *stop) {
        if ([dict[@"isSelect"] boolValue]) {
            self.currentServerName = key;
            *stop = YES;
        }
    }];
}

- (NSString *)currentServer {
    return self.realServerConfig[self.currentServerName][@"url"];
}

- (NSDictionary*) allServerConfigs {
    return [self.realServerConfig copy];
}

- (void) selectServerWithName:(NSString*)serverName
{
    NSDictionary * newConfig = self.realServerConfig[serverName];
    if (nil == newConfig) {
        return;
    }
    
    __block NSDictionary * oldConfig = nil;
    __block NSString * oldName = nil;
    [self.realServerConfig enumerateKeysAndObjectsUsingBlock:^(id key, id dict, BOOL *stop) {
        if ([dict[@"isSelect"] boolValue]) {
            oldConfig = dict;
            oldName = key;
            *stop = YES;
        }
    }];
    if (oldConfig) {
        NSMutableDictionary * mutableDict = [oldConfig mutableCopy];
        mutableDict[@"isSelect"] = @NO;
        self.realServerConfig[oldName] = mutableDict;
    }
    
    if (newConfig) {
        NSMutableDictionary * mutableDict = [newConfig mutableCopy];
        mutableDict[@"isSelect"] = @YES;
        self.realServerConfig[serverName] = mutableDict;
        self.currentServerName = serverName;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.realServerConfig forKey:kServerConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
