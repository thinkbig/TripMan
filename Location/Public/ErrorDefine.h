//
//  ErrorDefine.h
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#ifndef Location_ErrorDefine_h
#define Location_ErrorDefine_h

#define ERR_MAKE(code_, desc_)      [NSError errorWithDomain:@"clientErrDomain" code:(code_) userInfo:@{NSLocalizedDescriptionKey:(desc_ ? desc_ : @"")}]

typedef NS_ENUM(NSInteger, eCommonErrorCode) {
    eCommonError                = 10000,
    eBussinessError             = 10001,
    eBadDataError               = 10002,
    eInvalidInputError          = 10003,
    eNetworkError               = 10004,
};

#endif
