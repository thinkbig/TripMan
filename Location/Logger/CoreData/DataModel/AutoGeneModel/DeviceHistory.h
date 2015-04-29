//
//  DeviceHistory.h
//  TripMan
//
//  Created by taq on 4/28/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DeviceHistory : NSManagedObject

@property (nonatomic, retain) NSString * app_info;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * device_id;
@property (nonatomic, retain) NSString * device_info;
@property (nonatomic, retain) NSString * other_info;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSManagedObject *extend;

@end
