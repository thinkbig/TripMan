//
//  BCarAnnotationView.m
//  TripMan
//
//  Created by taq on 5/12/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BCarAnnotationView.h"

@implementation BCarAnnotationView

- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect bound = CGRectMake(0.f, 0.f, 32.f, 18.f);
        [self setBounds:bound];
        [self setBackgroundColor:[UIColor clearColor]];
        
        self.carIcon = [[UIImageView alloc] initWithFrame:bound];
        self.carIcon.contentMode = UIViewContentModeCenter;
        self.carIcon.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.carIcon];
        
        bound = CGRectInset(bound, 3, 0);
        self.mainLabel = [[UILabel alloc] initWithFrame:bound];
        self.mainLabel.font = [UIFont boldSystemFontOfSize:11];
        self.mainLabel.backgroundColor = [UIColor clearColor];
        self.mainLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.mainLabel];
    }
    return self;
}

- (void) updateWithIcon:(NSString*)imgName andText:(NSString*)str withAngle:(CGFloat)angle
{
    self.carIcon.image = [UIImage imageNamed:imgName];
    self.mainLabel.text = str;
    
    CGFloat rotateAngle = angle * M_PI/180.0;
    self.carIcon.transform = CGAffineTransformMakeRotation(rotateAngle);
    self.mainLabel.transform = CGAffineTransformMakeRotation(rotateAngle);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
