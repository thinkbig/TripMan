//
//  CarAssistorViewController.h
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "GViewController.h"
#import "RZCollectionTableView.h"

@interface CarAssistorViewController : GViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet RZCollectionTableView *suggestCollectionView;

@property (strong, nonatomic) UISearchBar *searchBar;

@end
