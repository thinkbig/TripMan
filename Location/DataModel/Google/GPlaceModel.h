//
//  GPlaceModel.h
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JSONModel.h"

@protocol GLocModel <NSObject>
@end

@interface GLocModel : JSONModel

@property (nonatomic, strong) NSNumber<Optional> * longitude;
@property (nonatomic, strong) NSNumber<Optional> * latitude;

- (CLLocationCoordinate2D) coordinate;

@end

////////////////////////////////////////////////////////////////////////////////

@interface GSnapPtModel : JSONModel

@property (nonatomic, strong) GLocModel<Optional> * location;
@property (nonatomic, strong) NSNumber<Optional> * originalIndex;
@property (nonatomic, strong) NSString<Optional> * placeId;

- (CLLocationCoordinate2D) coordinate;

@end
