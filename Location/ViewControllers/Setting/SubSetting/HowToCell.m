//
//  HowToCell.m
//  TripMan
//
//  Created by taq on 5/18/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "HowToCell.h"

@implementation HowToCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

//////////////////////////////////////////////////////////////////////////////////////////

@implementation HowToDetailCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

+ (CGFloat)heightForCellWithContent:(NSString*)str
{
    return [str boundingRectWithSize:CGSizeMake(290, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil].size.height + 30;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////

@implementation HowToImageDetailCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

+ (CGFloat)heightForCellWithContent:(NSString*)str
{
    return [str boundingRectWithSize:CGSizeMake(290, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil].size.height + 30;
}

@end

