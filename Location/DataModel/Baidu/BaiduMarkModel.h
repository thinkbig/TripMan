//
//  BaiduMarkModel.h
//  TripMan
//
//  Created by taq on 11/14/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "JSONModel.h"

@protocol BaiduMarkLocationModel <NSObject>
@end

@interface BaiduMarkLocationModel : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * lng;
@property (nonatomic, strong) NSNumber<Optional> * lat;

@end

////////////////////////////////////////////////////////////////////////////////////////////

@protocol BaiduMarkItemModel <NSObject>
@end

@interface BaiduMarkItemModel : JSONModel

@property (nonatomic, strong) NSString<Optional> * name;
@property (nonatomic, strong) NSNumber<Optional> * type;
@property (nonatomic, strong) BaiduMarkLocationModel<Optional> * location;

- (CLLocation*) clLocation;

@end

////////////////////////////////////////////////////////////////////////////////////////////

@interface BaiduMarkModel : JSONModel

@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * mainRoad;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * entrance;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * landMark;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * tollStation;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * trafficLight;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * serviceArea;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * gasStation;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * camera;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * other;
@property (nonatomic, strong) NSArray<BaiduMarkItemModel, Optional> * carPark;

@end
