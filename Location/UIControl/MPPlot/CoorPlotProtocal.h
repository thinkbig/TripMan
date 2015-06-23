//
//  CoorPlotProtocal.h
//  MPPlotExample
//
//  Created by taq on 12/1/14.
//  Copyright (c) 2014 mpow. All rights reserved.
//

#ifndef MPPlotExample_CoorPlotProtocal_h
#define MPPlotExample_CoorPlotProtocal_h

#import <UIKit/UIKit.h>

@protocol CoorLayoutProtocal <NSObject>

- (void) willLayoutIndex:(NSUInteger)idx;
- (void) didLayoutIndex:(NSUInteger)idx ofTopPoint:(CGPoint)point;

@end

#endif
