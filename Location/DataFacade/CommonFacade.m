//
//  CommonParser.m
//  tradeshiftHome
//
//  Created by taq on 5/14/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "CommonFacade.h"
#import "NSDictionary+QueryString.h"

@implementation CommonFacade

- (void)requestWithSuccess:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    [self request:nil success:success failure:failure];
}

- (void)request:(id)params success:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    [self fetchDataWithPath:[self getPath]
                requestType:[self requestType]
                      param:params
                    success:success
                    failure:failure];
}

- (void)fetchDataWithPath:(NSString *)resPath requestType:(eRequestType)type param:(NSDictionary*)param success:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    [self fetchDataWithPath:resPath requestType:type param:param constructBodyBlock:nil success:success failure:failure];
}

- (void)fetchDataWithPath:(NSString *)resPath requestType:(eRequestType)type param:(NSDictionary*)param constructBodyBlock:(void (^)(id <AFMultipartFormData> formData))block success:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    NSString * keyUrl = [self keyByUrl:[self baseUrl] resPath:resPath andParam:param];
    if (eCacheStrategyNone != [self cacheStrategy]) {
        id cachedResult = [self cachedResultForKey:keyUrl];
        if (cachedResult) {
            if (success) {
                success(cachedResult);
            }
            return;
        }
    }
    
    ClientConfig * config = [ClientConfig new];
    config.hostUrl = [self baseUrl];
    config.reqSerialType = [self requestSerializationType];
    config.respSerialType = [self respondSerializationType];
    
    AFHTTPSessionManager * client = [TSHttpClient sessionManagerWithConfig:config forceReset:NO];
    if (nil == client) {
        if (failure) failure(ERR_MAKE(eCommonError, @"fail to init SessionManager"));
        return;
    }
    
    //[client.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];

    [[self requestHeader] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [client.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    
    id realParam = nil;
    if (param && ![param isKindOfClass:[NSDictionary class]]) {
        realParam = param;
    } else {
        NSDictionary * commomParam = [self requestParam];
        realParam = [NSMutableDictionary dictionary];
        if (commomParam && [commomParam isKindOfClass:[NSDictionary class]]) {
            [realParam addEntriesFromDictionary:commomParam];
        }
        if (param && [param isKindOfClass:[NSDictionary class]]) {
            [realParam addEntriesFromDictionary:param];
        }
    }
    
    void (^successBlock)(id) = ^(id orig) {
        if (success || failure || eCacheStrategyNone != [self cacheStrategy]) {
            NSError * err = nil;
            id result = [self processingOrigResult:orig error:&err];
            if (nil == err) {
                id returnObj = [self parseRespData:result error:&err];
                if (nil == err) {
                    [self cacheObject:returnObj forKey:keyUrl];
                    if (success) {
                        success(returnObj);
                    }
                }
            }
            if (err && failure) {
                failure(err);
            }
        }
    };
    
    void (^failureBlock)(NSError *) = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };
    
    switch (type) {
        case eRequestTypeGet:
        {
            [client GET:resPath
             parameters:realParam
                success:^(NSURLSessionDataTask *task, id responseObject) {
                    self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                    successBlock(responseObject);
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                    failureBlock(error);
                }];
        }
            break;
        case eRequestTypePost:
            if (block) {
                [client POST:resPath parameters:realParam constructingBodyWithBlock:block success:^(NSURLSessionDataTask *task, id responseObject) {
                    self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                    successBlock(responseObject);
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                    failureBlock(error);
                }];
            } else {
                [client POST:resPath parameters:realParam success:^(NSURLSessionDataTask *task, id responseObject) {
                    self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                    successBlock(responseObject);
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                    failureBlock(error);
                }];
            }
            break;
        case eRequestTypePut:
        {
            [client PUT:resPath parameters:realParam success:^(NSURLSessionDataTask *task, id responseObject) {
                self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                successBlock(responseObject);
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                failureBlock(error);
            }];
        }
            break;
        case eRequestTypeDelete:
        {
            [client DELETE:resPath parameters:realParam success:^(NSURLSessionDataTask *task, id responseObject) {
                self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                successBlock(responseObject);
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                self.statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                failureBlock(error);
            }];
        }
            break;
            
        default:
            NSAssert(false, @"Unsupported request type=%u!!!", type);
            break;
    }
}

- (NSDictionary *) processingOrigResult:(id)origResult error:(NSError **)err
{
    return origResult;
}

- (eSerializationType)requestSerializationType {
    return eSerializationTextType;
}

- (eSerializationType)respondSerializationType {
    return eSerializationJsonType;
}

- (NSString*)baseUrl {
    return @"";
}

- (eRequestType)requestType {
    return eRequestTypePost;
}

- (NSString *)getPath {
    NSLog(@"please override this function %@ in subclass", NSStringFromSelector(_cmd));
    return @"";
}

- (id)parseRespData:(id)data error:(NSError **)err {
    return data;
}

- (NSDictionary*)requestHeader {
    return nil;
}

- (NSDictionary*)requestParam {
    return nil;
}


// catch function

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    if (nil == url) {
        return nil;
    }
    NSMutableString * key = [NSMutableString stringWithString:url];
    if (path) {
        if (![key hasSuffix:@"/"]) {
            [key appendString:@"/"];
        }
        [key appendString:path];
    }
    if (param) {
        NSString * paramStr = [param queryStringValue];
        if (![key containsString:@"?"]) {
            [key appendString:@"?"];
            [key appendString:paramStr];
        } else if ([key hasSuffix:@"?"] || [key hasSuffix:@"&"]) {
            [key appendString:paramStr];
        } else {
            [key appendString:@"?"];
            [key appendString:paramStr];
        }
    }
    return key;
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategyNone;
}

- (NSTimeInterval) expiredDuring {
    return MAXFLOAT;
}

- (id) cachedResultForKey:(NSString*)key
{
    if (nil == key) {
        return nil;
    }
    eCacheStrategy strategy = [self cacheStrategy];
    if (eCacheStrategyMemory == strategy) {
        return [[TSCache sharedInst] memCacheForKey:key];
    } else if (eCacheStrategyFile == strategy) {
        return [[TSCache sharedInst] fileCacheForKey:key];
    } else if (eCacheStrategySqlite == strategy) {
        return [[TSCache sharedInst] sqliteCacheForKey:key];
    }
    return nil;
}

- (void) cacheObject:(id)obj forKey:(NSString*)key
{
    if (nil == key || nil == obj) {
        return;
    }
    eCacheStrategy strategy = [self cacheStrategy];
    if (eCacheStrategyMemory == strategy) {
        [[TSCache sharedInst] setMemCache:obj forKey:key expiresIn:[self expiredDuring]];
    } else if (eCacheStrategyFile == strategy) {
        [[TSCache sharedInst] setFileCache:obj forKey:key expiresIn:[self expiredDuring]];
    } else if (eCacheStrategySqlite == strategy) {
        [[TSCache sharedInst] setSqlitCache:obj forKey:key expiresIn:[self expiredDuring]];
    }
}

@end
