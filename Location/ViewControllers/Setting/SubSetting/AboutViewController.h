//
//  AboutViewController.h
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GViewController.h"
#import "TTTAttributedLabel.h"

@interface AboutViewController : GViewController

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *emailLabel;

@end
