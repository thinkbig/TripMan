//
//  SuggestDetailViewController.m
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "SuggestDetailViewController.h"
#import "SuggestOverLayerCollectionViewController.h"

#define OVER_HEADER_HEIGHT      90

@interface SuggestDetailViewController ()

@property (nonatomic, strong) SuggestOverLayerCollectionViewController *    overLayerVC;

@end

@implementation SuggestDetailViewController

- (void)dealloc
{
    [((SuggestOverLayerCollectionViewController*)self.overLayerVC).collectionView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    CGRect scrollFrame = self.rootScrollView.bounds;
    scrollFrame.origin.y = -64;
    // add header and content
    if (nil == self.mapView) {
        self.mapView = [[MKMapView alloc] initWithFrame:scrollFrame];
        [self.rootScrollView addSubview:self.mapView withAcceleration:CGPointMake(0.0, 0.5)];
    }
    
    if (nil == self.overLayerVC) {
        self.overLayerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestOverLay"];
        scrollFrame.size.height -= 64;
        scrollFrame.origin.y = (scrollFrame.size.height - OVER_HEADER_HEIGHT);
        self.overLayerVC.view.frame = scrollFrame;
        self.overLayerVC.collectionView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_bg"]];
        [self.rootScrollView addSubview:self.overLayerVC.view];
    }
    CGSize contentSize = self.rootScrollView.frame.size;
    contentSize.height = CGRectGetMaxY(scrollFrame);
    self.rootScrollView.contentSize = contentSize;
    
    [self.overLayerVC.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"]) {
        NSValue *oldVal = [change objectForKey:NSKeyValueChangeOldKey];
        NSValue *newVal = [change objectForKey:NSKeyValueChangeNewKey];
        if (nil == newVal || nil == oldVal || [oldVal isEqual:newVal]) {
            return;
        }
        CGRect oldRect = self.overLayerVC.collectionView.frame;
        oldRect.size = [newVal CGSizeValue];
        self.overLayerVC.collectionView.frame = oldRect;
        
        CGSize contentSize = self.rootScrollView.contentSize;
        CGRect scrollFrame = self.rootScrollView.bounds;
        contentSize.height = (scrollFrame.size.height - OVER_HEADER_HEIGHT) + oldRect.size.height - 64;
        self.rootScrollView.contentSize = contentSize;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
