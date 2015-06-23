//
//  CTBadge.h
//  TripMan
//
//  Created by taq on 6/10/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"

@interface CTBadge : JSONModel

@property (nonatomic, strong) NSString<Optional> *    bgId;
@property (nonatomic, strong) NSString<Optional> *    name;
@property (nonatomic, strong) NSString<Optional> *    desc;
@property (nonatomic, strong) NSDate<Optional> *      rewardDate;
@property (nonatomic, strong) NSString<Optional> *    imgUrl;

@end
