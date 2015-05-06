//
//  CarMaintainInfo.h
//  TripMan
//
//  Created by taq on 5/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"

@interface CarMaintainInfo : JSONModel

// 用户手动输入的信息
@property (nonatomic, strong) NSDate *                      userUpdateDate;
@property (nonatomic, strong) NSNumber<Optional> *          userTotalDist;
@property (nonatomic, strong) NSDate<Optional> *            userDateBuy;
@property (nonatomic, strong) NSNumber<Optional> *          userLastMaintainDist;
@property (nonatomic, strong) NSDate<Optional> *            userLastMaintainDate;

// 阈值信息
@property (nonatomic, strong) NSNumber<Optional> *          thresMaintainDist;
@property (nonatomic, strong) NSNumber<Optional> *          thresMaintainDuration;

// 根据用户行驶记录，动态信息
// 统计从userUpdateDate到dynamicEndDate中间的旅程数据
// dynamicEndDate不会统计今天，因为可能正在行驶中
@property (nonatomic, strong) NSDate<Optional> *            dynamicEndDate;
@property (nonatomic, strong) NSNumber<Optional> *          dynamicDist;    // 截止到昨天的数据，和dynamicEndDate对应

- (void) updateDynamicInfo;
- (void) load;
- (void) save;

@end
