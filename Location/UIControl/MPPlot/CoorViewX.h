//
//  CoorViewX.h
//  MPPlotExample
//
//  Created by taq on 12/1/14.
//  Copyright (c) 2014 mpow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoorPlotProtocal.h"

typedef UILabel * (^GeneCoorLabelBlock)(NSString*);

@interface CoorViewX : UIView <CoorLayoutProtocal>

@property (nonatomic, strong) NSArray *             coorStrArray;
@property (nonatomic, copy) GeneCoorLabelBlock      geneLabelBlock;

@end
