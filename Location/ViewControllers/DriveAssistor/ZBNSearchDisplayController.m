//
//  ZBNSearchDisplayController.m
//  TripMan
//
//  Created by taq on 11/21/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "ZBNSearchDisplayController.h"

@interface ZBNSearchDisplayController () {
    BOOL            _hideContentNavBar;
    CGRect          _oldSearchFrame;
    CGRect          _oldSearchSupperFrame;
}

@end

@implementation ZBNSearchDisplayController

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController {
    self = [super init];
    
    if (self) {
        _searchBar = searchBar;
        _searchBar.delegate = self;
        _searchContentsController = viewController;
        
        CGFloat y = 80.0f;
        CGFloat height = _searchContentsController.view.frame.size.height - y;
        
        _searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, y, _searchContentsController.view.frame.size.width, height)];
        _searchResultsTableView.scrollsToTop = NO;
    }
    
    return self;
}

- (void)setSearchResultsDataSource:(id<UITableViewDataSource>)searchResultsDataSource {
    _searchResultsTableView.dataSource = searchResultsDataSource;
}

- (void)setSearchResultsDelegate:(id<UITableViewDelegate>)searchResultsDelegate {
    _searchResultsTableView.delegate = searchResultsDelegate;
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    if (!visible) {
        [_searchBar resignFirstResponder];
        _searchBar.text = nil;
        _searchBar.showsCancelButton = NO;
    }
    
    if (visible && [self.delegate respondsToSelector:@selector(searchDisplayControllerWillBeginSearch:)]) {
        [self.delegate searchDisplayControllerWillBeginSearch:self];
    } else if (!visible && [self.delegate respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)]) {
        [self.delegate searchDisplayControllerWillEndSearch:self];
    }
    
    [_searchContentsController.navigationController setNavigationBarHidden:(_hideContentNavBar ? YES : visible) animated:YES];
    
    float alpha = 0;
    CGRect searchRect = _oldSearchFrame;
    CGRect searchParent = _oldSearchSupperFrame;
    
    if (visible) {
        _searchResultsTableView.alpha = 0;
        [_searchContentsController.view addSubview:_searchResultsTableView];
        alpha = 1.0;
        searchParent.origin.y = 20;
        searchRect.size.width = searchParent.size.width;
        searchRect.origin.x = 0;
    }
    
    UIView * scrollView = _searchBar.superview;
    while (![scrollView isKindOfClass:[UIScrollView class]]) {
        scrollView = scrollView.superview;
    }
    if ([scrollView isKindOfClass:[UIScrollView class]]) {
        ((UIScrollView *)scrollView).scrollEnabled = !visible;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            if ([scrollView isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView *)scrollView).contentOffset = CGPointZero;
            }
            _searchResultsTableView.alpha = alpha;
            self.searchBar.frame = searchRect;
            self.searchBar.superview.frame = searchParent;
        } completion:^(BOOL finished) {
            self.active = visible;
        }];
    } else {
        _searchResultsTableView.alpha = alpha;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([self.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [self.delegate searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.delegate respondsToSelector:@selector(textDidChange:)]) {
        [self.delegate textDidChange:searchText];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [self setActive:YES animated:YES];
    [_searchResultsTableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_searchResultsTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //_searchBar.tintColor = [UIColor clearColor];
    [self setActive:NO animated:YES];
    [self.searchResultsTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    _hideContentNavBar = _searchContentsController.navigationController.navigationBarHidden;
    _oldSearchFrame = self.searchBar.frame;
    _oldSearchSupperFrame = self.searchBar.superview.frame;
    
    CGFloat y = CGRectGetMaxY(_oldSearchSupperFrame) + 5;
    CGFloat height = _searchContentsController.view.frame.size.height - y;
    _searchResultsTableView.frame = CGRectMake(0.0f, y, _searchContentsController.view.frame.size.width, height);
    
    //_searchBar.tintColor = UIColorFromRGB(0x20a0e9);
    return YES;
}

@end
