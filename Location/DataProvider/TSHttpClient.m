//
//  TSHttpClient.m
//  tradeshiftHome
//
//  Created by taq on 5/14/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "TSHttpClient.h"
#import <objc/runtime.h>

@implementation ClientConfig

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if ( nil != self ) {
        self.cfgName = [decoder decodeObjectForKey:@"cfgName"];
        self.hostUrl = [decoder decodeObjectForKey:@"hostUrl"];
        self.reqSerialType = (eSerializationType)[decoder decodeIntegerForKey:@"reqSerialType"];
        self.respSerialType = (eSerializationType)[decoder decodeIntegerForKey:@"respSerialType"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_cfgName forKey:@"cfgName"];
    [encoder encodeObject:_hostUrl forKey:@"hostUrl"];
    [encoder encodeInteger:_reqSerialType forKey:@"reqSerialType"];
    [encoder encodeInteger:_respSerialType forKey:@"respSerialType"];
}

- (id)copyWithZone:(NSZone *)zone
{
    ClientConfig *entry = [[[self class] allocWithZone:zone] init];
    entry.cfgName = [_cfgName copy];
    entry.hostUrl = [_hostUrl copy];
    entry.reqSerialType = _reqSerialType;
    entry.respSerialType = _respSerialType;
    return entry;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    ClientConfig *entry = (ClientConfig*)object;
    return [entry.hostUrl isEqualToString:self.hostUrl] && entry.reqSerialType == self.reqSerialType && entry.respSerialType == self.respSerialType;
}

- (NSUInteger)hash
{
    return 100*[self.hostUrl hash] + 10*self.reqSerialType + self.reqSerialType;
}

- (BOOL) isValid
{
    return [self.hostUrl hasPrefix:@"http:"] || [self.hostUrl hasPrefix:@"https:"];
}

- (NSString*) clientKey
{
    return [_hostUrl stringByAppendingFormat:@"-%d-%d", self.reqSerialType, self.respSerialType];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface TSHttpClient ()

@property (nonatomic, strong) NSMutableDictionary *     networkManagerDict;

@end

@implementation TSHttpClient

static TSHttpClient * _sharedClient = nil;

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[TSHttpClient alloc] init];
    });
    return _sharedClient;
}

- (id)init {
    self = [super init];
    if (self) {
        _networkManagerDict = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (id) networkManagerForKey:(NSString *)clientKey {
    return  [_networkManagerDict objectForKey:clientKey];
}

- (void)setNetworkManager:(id)client forKey:(NSString *)clientKey {
    if (clientKey) {
        if (client) {
            [_networkManagerDict setObject:client forKey:clientKey];
        } else {
            [_networkManagerDict removeObjectForKey:clientKey];
        }
    }
}

+ (AFHTTPSessionManager *) sessionManagerWithConfig:(ClientConfig*)config forceReset:(BOOL)force
{
    AFHTTPSessionManager * manager = [[TSHttpClient sharedClient] networkManagerForKey:[config clientKey]];
    if (!force && manager) {
        return manager;
    }
    
    return [self geneSessionManager:config];
}

+ (AFHTTPSessionManager *) geneSessionManager:(ClientConfig*)config
{
    if (![config isValid]) {
        return nil;
    }
    NSURL * url = [NSURL URLWithString:config.hostUrl];
    AFHTTPSessionManager * client = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    if (client)
    {
        UIDevice * device = [UIDevice currentDevice];
        [client.requestSerializer setValue:[[NSLocale preferredLanguages] objectAtIndex:0] forHTTPHeaderField:@"Accept-Language"];
        [client.requestSerializer setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forHTTPHeaderField:@"Version"];
        [client.requestSerializer setValue:[NSString stringWithFormat:@"%@, %@-%@", device.localizedModel, device.systemName, device.systemVersion] forHTTPHeaderField:@"User-Agent"];
        client.requestSerializer.timeoutInterval = 10;
        
        if (eSerializationJsonType == config.reqSerialType) {
            client.requestSerializer = [AFJSONRequestSerializer serializer];
        } else {
            client.requestSerializer = [AFHTTPRequestSerializer serializer];
        }
        
        if (eSerializationJsonType == config.respSerialType) {
            client.responseSerializer = [AFJSONResponseSerializer serializer];
            [client.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        } else {
            client.responseSerializer = [AFHTTPResponseSerializer serializer];
        }        
        
        [[TSHttpClient sharedClient] setNetworkManager:client forKey:[config clientKey]];
    }
    
    return client;
}

@end
