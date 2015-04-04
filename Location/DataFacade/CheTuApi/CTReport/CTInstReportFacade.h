//
//  CTInstReportFacade.h
//  TripMan
//
//  Created by taq on 4/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaseChetuFacade.h"
#import "CTInstReportModel.h"

@interface CTInstReportFacade : BaseChetuFacade

@property (nonatomic, strong) CTInstReportModel *       reportModel;
@property (nonatomic) BOOL                              ignore;

@end
