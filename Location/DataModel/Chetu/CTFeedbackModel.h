//
//  CTFeedbackModel.h
//  TripMan
//
//  Created by taq on 5/15/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"

@interface CTFeedbackModel : JSONModel

@property (nonatomic, strong) NSString *                contact;
@property (nonatomic, strong) NSNumber<Optional> *      contact_type;   // 判断contact是qq，手机，email或者其他
@property (nonatomic, strong) NSString<Optional> *      loc;
@property (nonatomic, strong) NSString<Optional> *      city;
@property (nonatomic, strong) NSNumber<Optional> *      type;           // 反馈类型，目前没有用到
@property (nonatomic, strong) NSString<Optional> *      msg;
@property (nonatomic, strong) NSString<Optional> *      addi;           // 其他内容

- (void) updateLocation;

@end
