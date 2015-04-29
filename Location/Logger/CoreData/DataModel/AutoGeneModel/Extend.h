//
//  Extend.h
//  TripMan
//
//  Created by taq on 4/28/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Extend : NSManagedObject

@property (nonatomic, retain) NSNumber * int_ext1;
@property (nonatomic, retain) NSNumber * int_ext2;
@property (nonatomic, retain) NSNumber * int_ext3;
@property (nonatomic, retain) NSString * string_ext1;
@property (nonatomic, retain) NSString * string_ext2;
@property (nonatomic, retain) NSString * string_ext3;
@property (nonatomic, retain) NSNumber * double_ext1;
@property (nonatomic, retain) NSNumber * double_ext2;
@property (nonatomic, retain) NSNumber * double_ext3;
@property (nonatomic, retain) NSData * bin_ext1;
@property (nonatomic, retain) NSDate * date_ext1;
@property (nonatomic, retain) NSDate * date_ext2;
@property (nonatomic, retain) NSNumber * bool_ext1;
@property (nonatomic, retain) NSNumber * bool_ext2;

@end
