//
//  CommonParser.h
//  tradeshiftHome
//
//  Created by taq on 5/14/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonFacadeDefine.h"
#import "TSHttpClient.h"
#import "TSCache.h"

typedef NS_ENUM(NSUInteger, eRequestType) {
    eRequestTypeGet = 0,
    eRequestTypePost,
    eRequestTypePut,
    eRequestTypeDelete
};

typedef NS_ENUM(NSUInteger, eCacheStrategy) {
    eCacheStrategyNone = 0,
    eCacheStrategyMemory,
    eCacheStrategyFile,
    eCacheStrategySqlite
};

typedef NS_ENUM(NSUInteger, eCallbackStrategy) {
    eCallBackCacheIfExist = 0,
    eCallBackCacheIfRequestFail,
    eCallBackCacheAndRequestNew
};

@interface CommonFacade : NSObject

@property (nonatomic, assign) NSUInteger statusCode;

// for public use
- (void)requestWithSuccess:(successFacadeBlock)success failure:(failureFacadeBlock)failure;
- (void)request:(id)params success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;

// for child class use
- (void)fetchDataWithPath:(NSString *)resPath requestType:(eRequestType)type param:(NSDictionary*)param success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;
- (void)fetchDataWithPath:(NSString *)resPath requestType:(eRequestType)type param:(NSDictionary*)param constructBodyBlock:(void (^)(id <AFMultipartFormData> formData))block success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;


// Subclass may inherite the functions below

// Incase of xml format OR json with a common header (like return code or message), check the validation of the orig data and return the CLEAN data. If error accur at any case, return nil and set the err param.
- (id) processingOrigResult:(id)origResult error:(NSError **)err;

// request info to override
- (eSerializationType)requestSerializationType;
- (eSerializationType)respondSerializationType;
- (NSString*)baseUrl;
- (eRequestType)requestType;
- (NSString *)getPath;
- (NSDictionary*)requestHeader;
- (NSDictionary*)requestParam;

- (id)parseRespData:(id)data error:(NSError **)err;


// cache function

- (eCacheStrategy) cacheStrategy;       // default for no cache
- (NSTimeInterval) expiredDuring;
- (eCallbackStrategy) callbackStrategy; // only work when cache strategy is on

// override this if u need custom key for caching
- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param;

// no need to override these 2 functions below
- (id) cachedResultForKey:(NSString*)key;
- (void) cacheObject:(id)obj forKey:(NSString*)key;

// helper functin
+ (id) fromJsonString:(NSString*)str;

@end
