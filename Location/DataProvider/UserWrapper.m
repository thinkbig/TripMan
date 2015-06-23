//
//  UserWrapper.m
//  tradeshiftHome
//
//  Created by taq on 5/16/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import "UserWrapper.h"

#define KEY_USER_CURRENT_CONFIG             @"kUserCurConfig"

@implementation UserSecret

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if ( nil != self ) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.account = [decoder decodeObjectForKey:@"account"];
        self.curCarNumber = [decoder decodeObjectForKey:@"curCarNumber"];
        self.authSecret = [decoder decodeObjectForKey:@"authSecret"];
        self.countryCode = [decoder decodeObjectForKey:@"countryCode"];
        self.loginType = (eLoginType)[decoder decodeIntegerForKey:@"loginType"];
        self.oauth2AccessToken = [decoder decodeObjectForKey:@"oauth2AccessToken"];
        self.oauth2Expires = [decoder decodeObjectForKey:@"oauth2Expires"];
        self.userId = [decoder decodeObjectForKey:@"userId"];
        self.carInfo = [decoder decodeObjectForKey:@"carInfo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_account forKey:@"account"];
    [encoder encodeObject:_curCarNumber forKey:@"curCarNumber"];
    [encoder encodeObject:_authSecret forKey:@"authSecret"];
    [encoder encodeObject:_countryCode forKey:@"countryCode"];
    [encoder encodeInt:_loginType forKey:@"loginType"];
    [encoder encodeObject:_oauth2AccessToken forKey:@"oauth2AccessToken"];
    [encoder encodeObject:_oauth2Expires forKey:@"oauth2Expires"];
    [encoder encodeObject:_userId forKey:@"userId"];
    [encoder encodeObject:_carInfo forKey:@"carInfo"];
}

- (id)copyWithZone:(NSZone *)zone
{
    UserSecret *entry = [[[self class] allocWithZone:zone] init];
    entry.name = [_name copy];
    entry.account = [_account copy];
    entry.authSecret = [_authSecret copy];
    entry.loginType = _loginType;
    entry.oauth2AccessToken = [_oauth2AccessToken copy];
    entry.oauth2Expires = [_oauth2Expires copy];
    entry.userId = [_userId copy];
    return entry;
}

- (void)setAccount:(NSString *)account
{
    _account = account;
    if (nil == _name) {
        self.name = account;
    }
}

- (id) initWithName:(NSString*)name andPassword:(NSString*)password
{
    self = [super init];
    if (self) {
        self.account = name;
        self.authSecret = [[[NSString stringWithFormat:@"%@:%@", name, password] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    }
    return self;
}

- (BOOL) isValidForOauth2;
{
    return (nil != self.oauth2AccessToken) && (nil != self.oauth2Expires) && ([self.oauth2Expires compare:[NSDate date]] != NSOrderedAscending);
}

- (BOOL) isLogin
{
    switch (self.loginType) {
        case eLoginTypeOauth2:
            return [self isValidForOauth2];
        case eLoginTypeQQ:
            break;
            
        default:
            break;
    }

    return NO;
}

- (void) resetLogin:(BOOL)resetAll;
{
    if (resetAll) {
        self.account = nil;
    }
    self.authSecret = nil;
    self.oauth2AccessToken = nil;
    self.oauth2Expires = nil;
    self.userId = nil;
    self.loginType = eLoginTypeNotLogin;
}

@end

/////////////////////////////////////////////////////

@interface UserWrapper ()

@property (nonatomic, copy) loginBlock          block;

@end

@implementation UserWrapper

static UserWrapper * _sharedInst = nil;

+ (instancetype)sharedInst {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInst = [[UserWrapper alloc] init];
    });
    return _sharedInst;
}

- (id)init {
    self = [super init];
    if (self) {
        _userSecret = [[UserSecret alloc] init];
        [self restoreLastConfig];
    }
    return self;
}

- (void) restoreLastConfig
{
    UserSecret * config = [[TSCache sharedInst] keychainCacheForKey:KEY_USER_CURRENT_CONFIG];
    if ([config isKindOfClass:[UserSecret class]]) {
        self.userSecret = config;
    }
}

- (void) setupConfig:(UserSecret*)config
{
    if ([config isKindOfClass:[UserSecret class]]) {
        self.userSecret = config;
        [self saveConfig];
    }
}

- (void) saveConfig
{
    [[TSCache sharedInst] setKeychainCache:self.userSecret forKey:KEY_USER_CURRENT_CONFIG];
}

- (BOOL) isLogin
{
    return [self.userSecret isLogin];
}

- (BOOL) canAutoLogin
{
    return self.userSecret.account && self.userSecret.authSecret;
}

- (void) logout
{
    // do not care if really logout from server, just clear all user login info
    [self resetLogin:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:KEY_USER_LOGOUT object:nil];
}

- (void) resetLogin:(BOOL)resetAll;
{
    [_userSecret resetLogin:resetAll];
    [self saveConfig];
}

- (void) reLogin:(BOOL)autoLogin
{
    [self reLogin:autoLogin withCompleteBlock:nil];
}

- (void) reLogin:(BOOL)autoLogin withCompleteBlock:(loginBlock)block
{
    self.block = block;
    
    [self logout];
    if (autoLogin && [self canAutoLogin]) {
        [self realLoginSuccess:nil failure:^(NSError * err) {
            // show login view controller
        }];
    } else {
        // show login view controller
    }
}

- (void) loginWithUserSecret:(UserSecret*)secret withSuccess:(void (^)(id result))success failure:(void (^)(NSError * err))failure;
{
    if (secret) {
        self.userSecret = secret;
        [self realLoginSuccess:success failure:failure];
    }
}

- (void) realLoginSuccess:(void (^)(id result))success failure:(void (^)(NSError *))failure
{

}

@end
