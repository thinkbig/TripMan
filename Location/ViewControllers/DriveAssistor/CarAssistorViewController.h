//
//  CarAssistorViewController.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "RZCollectionTableView.h"
#import "ZBNSearchDisplayController.h"

@interface CarAssistorViewController : GViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, ZBNSearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet RZCollectionTableView *suggestCollectionView;

@property (strong, nonatomic) UISearchBar *searchBar;

@end
