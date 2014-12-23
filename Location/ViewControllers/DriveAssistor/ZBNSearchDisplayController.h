//
//  ZBNSearchDisplayController.h
//  TripMan
//
//  Created by taq on 11/21/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZBNSearchDisplayDelegate;

@interface ZBNSearchDisplayController : NSObject<UISearchBarDelegate>

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)visible animated:(BOOL)animated;

@property(nonatomic,assign) id<ZBNSearchDisplayDelegate> delegate;
@property(nonatomic, getter = isActive) BOOL active;
@property(nonatomic, readonly) UISearchBar *searchBar;
@property(nonatomic, readonly) UIViewController *searchContentsController;
@property(nonatomic, readonly) UITableView *searchResultsTableView;
@property(nonatomic, assign) id<UITableViewDataSource> searchResultsDataSource;
@property(nonatomic, assign) id<UITableViewDelegate> searchResultsDelegate;

@end

@protocol ZBNSearchDisplayDelegate <NSObject>

@optional

- (void)searchDisplayControllerWillBeginSearch:(ZBNSearchDisplayController *)controller;
- (void)searchDisplayControllerDidBeginSearch:(ZBNSearchDisplayController *)controller;
- (void)searchDisplayControllerWillEndSearch:(ZBNSearchDisplayController *)controller;
- (void)searchDisplayControllerDidEndSearch:(ZBNSearchDisplayController *)controller;
- (void)textDidChange:(NSString *)searchText;
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope;

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar;
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;

@end
