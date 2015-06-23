//
//  UserWrapper.h
//  tradeshiftHome
//
//  Created by taq on 5/16/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSCache.h"

typedef NS_ENUM(NSInteger, eLoginType) {
    eLoginTypeNotLogin = 0,
    eLoginTypeOauth2 = 1,
    eLoginTypeQQ = 2,
};

#define KEY_USER_LOGIN_SUCCESS          @"kLoginSuccess"
#define KEY_USER_LOGOUT                 @"kLogout"

typedef void (^loginBlock)(NSString * uid, NSError * err);

@interface UserSecret : NSObject

@property (nonatomic, strong) NSString * name;          // user nick name
@property (nonatomic, strong) NSString * account;       // login account
@property (nonatomic, strong) NSString * curCarNumber;  // 当前车牌号码，苏Exxxxx
@property (nonatomic, strong) NSString * countryCode;   // support multi country (CN for chima)
@property (nonatomic, strong) NSString * authSecret;    // "base64(username:password)" do not save this
@property (nonatomic, strong) NSString * userId;        // user accout id (unique Userid)
@property (nonatomic, strong) NSMutableDictionary * carInfo;    // {车牌：车架号码}
@property (nonatomic) eLoginType         loginType;

// login info for oath2
@property (nonatomic, strong) NSString * oauth2AccessToken;
@property (nonatomic, strong) NSDate *   oauth2Expires;

- (id) initWithName:(NSString*)name andPassword:(NSString*)password;

- (BOOL) isValidForOauth2;
- (BOOL) isLogin;
- (void) resetLogin:(BOOL)resetAll;

@end

/////////////////////////////////////////////////////////////////////////

@interface UserWrapper : NSObject

@property (nonatomic, strong)   UserSecret *      userSecret;

+ (instancetype)sharedInst;

- (BOOL) isLogin;
- (void) logout;
- (void) resetLogin:(BOOL)resetAll;
- (void) reLogin:(BOOL)autoLogin;
- (void) reLogin:(BOOL)autoLogin withCompleteBlock:(loginBlock)block;
- (void) loginWithUserSecret:(UserSecret*)secret withSuccess:(void (^)(id result))success failure:(void (^)(NSError * err))failure;

@end
