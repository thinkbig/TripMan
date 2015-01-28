//
//  TSPair.h
//  tradeshiftHome
//
//  Created by taq on 9/25/14.
//  Copyright (c) 2014 Tradeshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPair : NSObject

@property (nonatomic, strong) id            first;
@property (nonatomic, strong) id            second;
@property (nonatomic, strong) NSString *    desp;
@property (nonatomic, strong) NSString *    exInfo;

@end

static inline TSPair * TSPairMake(id first, id second, NSString * description)
{
    TSPair * pair = [[TSPair alloc] init];
    pair.first = first;
    pair.second = second;
    pair.desp = description;
    return pair;
}
