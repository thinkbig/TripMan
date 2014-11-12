//
//  BaiduWeatherModel.h
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "JSONModel.h"

@protocol BaiduWeatherDetailModel <NSObject>
@end

@interface BaiduWeatherDetailModel : JSONModel

@property (nonatomic, strong) NSString<Optional> * date;
@property (nonatomic, strong) NSString<Optional> * weather;
@property (nonatomic, strong) NSString<Optional> * wind;
@property (nonatomic, strong) NSString<Optional> * temperature;

@end

////////////////////////////////////////////////////////////////////////////////////////////

@protocol BaiduWeatherSuggestModel <NSObject>
@end

@interface BaiduWeatherSuggestModel : JSONModel

@property (nonatomic, strong) NSString<Optional> * title;
@property (nonatomic, strong) NSString<Optional> * zs;
@property (nonatomic, strong) NSString<Optional> * tipt;
@property (nonatomic, strong) NSString<Optional> * des;

@end

////////////////////////////////////////////////////////////////////////////////////////////

@interface BaiduWeatherModel : JSONModel

@property (nonatomic, strong) NSString<Optional> * currentCity;
@property (nonatomic, strong) NSString<Optional> * pm25;
@property (nonatomic, strong) NSArray<Optional, BaiduWeatherSuggestModel> * index;
@property (nonatomic, strong) NSArray<Optional, BaiduWeatherDetailModel> * weather_data;

@end
