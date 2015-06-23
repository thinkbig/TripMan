//
//  FAQCell.m
//  TripMan
//
//  Created by taq on 5/18/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "FAQCell.h"

@implementation FAQCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

//////////////////////////////////////////////////////////////////////////////////////////

@implementation FAQDetailCell

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


