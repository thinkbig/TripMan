//
//  BaseChetuFacade.h
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CommonFacade.h"
#import "BussinessDataProvider.h"

@interface BaseChetuFacade : CommonFacade

- (NSString*)coor2String:(CLLocationCoordinate2D)coor;

//- (NSMutableString *)ctPathWithResPath:(NSString*)resPath;

@end
