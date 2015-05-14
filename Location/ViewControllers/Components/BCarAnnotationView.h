//
//  BCarAnnotationView.h
//  TripMan
//
//  Created by taq on 5/12/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKAnnotationView.h"

@interface BCarAnnotationView : BMKAnnotationView

@property (nonatomic, strong) UIImageView *     carIcon;
@property (nonatomic, strong) UILabel *         mainLabel;

- (void) updateWithIcon:(NSString*)imgName andText:(NSString*)str withAngle:(CGFloat)angle;

@end
