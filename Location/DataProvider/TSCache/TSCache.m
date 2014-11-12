//
//  TSConfig.m
//  tradeshiftHome
//
//  Created by taq on 5/22/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSCache.h"
#import "FXKeychain.h"
#import "CacheKit.h"
#import "NSString+MD5.h"

@interface TSCache ()

@property (nonatomic, strong) CKMemoryCache *           memCache;
@property (nonatomic, strong) CKFileCache *             fileCache;
@property (nonatomic, strong) CKSQLiteCache *           sqliteCache;
@property (nonatomic, strong) FXKeychain *              keychainStorage;

@end

///////////////////////////////////////////////////////////////////////////////

@implementation TSCache

static TSCache * _sharedInst = nil;

+ (instancetype)sharedInst {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInst = [[TSCache alloc] init];
    });
    return _sharedInst;
}


- (CKMemoryCache*) memCache {
    if (nil == _memCache) {
        _memCache = [[CKMemoryCache alloc] initWithName:@"TSMemCache"];
    }
    return _memCache;
}

- (CKFileCache*) fileCache {
    if (nil == _fileCache) {
        _fileCache = [[CKFileCache alloc] initWithName:@"TSFileCache"];
    }
    return _fileCache;
}

- (CKSQLiteCache*) sqliteCache {
    if (nil == _sqliteCache) {
        _sqliteCache = [[CKSQLiteCache alloc] initWithName:@"TSSqliteCache"];
    }
    return _sqliteCache;
}

- (FXKeychain*) keychainStorage {
    if (nil == _keychainStorage) {
        NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
        _keychainStorage = [[FXKeychain alloc] initWithService:bundleID accessGroup:@"TSCurrentUser"];
    }
    return _keychainStorage;
}


// seperate key val config

- (NSString*) shortenKey:(NSString*)origKey
{
    return [NSString stringWithFormat:@"TS_%@_%@", [origKey MD5], [[origKey substringFromIndex:origKey.length/2] MD5]];
}

- (id) memCacheForKey:(NSString*)key {
    return [self.memCache objectForKey:[self shortenKey:key]];
}

- (void) setMemCache:(id)obj forKey:(NSString*)key {
    [self.memCache setObject:obj forKey:[self shortenKey:key]];
}

- (void) setMemCache:(id)obj forKey:(NSString*)key expiresIn:(NSTimeInterval)expire {
    [self.memCache setObject:obj forKey:[self shortenKey:key] expiresIn:expire];
}


- (id) sqliteCacheForKey:(NSString *)key {
    return [self.sqliteCache objectForKey:[self shortenKey:key]];
}

- (void) setSqlitCache:(id)obj forKey:(NSString *)key {
    [self.sqliteCache setObject:obj forKey:[self shortenKey:key]];
}

- (void) setSqlitCache:(id)obj forKey:(NSString *)key expiresIn:(NSTimeInterval)expire {
    [self.sqliteCache setObject:obj forKey:[self shortenKey:key] expiresIn:expire];
}


- (id) fileCacheForKey:(NSString *)key {
    return [self.fileCache objectForKey:[self shortenKey:key]];
}

- (void) setFileCache:(id)obj forKey:(NSString *)key {
    [self.fileCache setObject:obj forKey:[self shortenKey:key]];
}

- (void) setFileCache:(id)obj forKey:(NSString *)key expiresIn:(NSTimeInterval)expire {
    [self.fileCache setObject:obj forKey:[self shortenKey:key] expiresIn:expire];
}


- (id) keychainCacheForKey:(NSString*)key {
    return [self.keychainStorage objectForKey:[self shortenKey:key]];
}

- (void) setKeychainCache:(id)obj forKey:(NSString*)key {
    [self.keychainStorage setObject:obj forKey:[self shortenKey:key]];
}


@end
