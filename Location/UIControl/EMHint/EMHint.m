//
//  EMHintState.m
//  ModalStateOverviewTest
//
//  Created by Eric McConkie on 3/6/12.
/*
Copyright (c) 2012 Eric McConkie

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "EMHint.h"

@implementation EMHint

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bgColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6];
    }
    return self;
}

-(void)_onTap:(UITapGestureRecognizer*)tap
{
    BOOL flag = YES;
    if ([self.hintDelegate respondsToSelector:@selector(hintStateShouldCloseIfPermitted:)]) {
        flag = [self.hintDelegate hintStateShouldCloseIfPermitted:self];
    }
    if(!flag)return;
    if ([self.hintDelegate respondsToSelector:@selector(hintStateWillClose:)]) {
        [self.hintDelegate hintStateWillClose:self];
    }
    
    [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseOut 
                     animations:^(){
                         [_modalView setAlpha:0.0];
                     } 
                     completion:^(BOOL finished){
                         [_modalView removeFromSuperview];
                         _modalView = nil;
                         if ([self.hintDelegate respondsToSelector:@selector(hintStateDidClose:)])
                         {
                             [self.hintDelegate hintStateDidClose:self];
                         }

                     }];
    
}

-(void)_addTap
{
    UITapGestureRecognizer *tap = tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_onTap:)];
    [_modalView addGestureRecognizer:tap]; 
}

-(void)clear
{
    [_modalView removeFromSuperview];
    _modalView = nil;
}

-(UIView*)modalView
{
    return _modalView;
}

-(void)presentModalMessage:(NSString*)message where:(UIView*)presentationPlace
{
    //incase we have many in a row
    if(_modalView!=nil)
        [self clear];
    
    if ([self.hintDelegate respondsToSelector:@selector(hintStateViewsToHint:)]) {
        NSArray *viewArray = [self.hintDelegate hintStateViewsToHint:self];
        if(viewArray!=nil)
            _modalView = [[EMHintsView alloc] initWithFrame:presentationPlace.frame forViews:viewArray parentView:presentationPlace];
    }
    
    if ([self.hintDelegate respondsToSelector:@selector(hintStateRectsToHint:)]) {
        NSArray* rectArray = [self.hintDelegate hintStateRectsToHint:self];
        if (rectArray != nil)
            _modalView = [[EMHintsView alloc] initWithFrame:presentationPlace.frame withRects:rectArray];
    }
    
    if (_modalView==nil)
        _modalView = [[EMHintsView alloc] initWithFrame:presentationPlace.frame];
    
    _modalView.backgroundColor = self.bgColor;
    [_modalView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    _modalView.alpha = 0;
    [presentationPlace addSubview:_modalView];
    
    UIView *v = nil;
    if ([[self hintDelegate] respondsToSelector:@selector(hintStateViewForDialog:)]) {
        v = [self.hintDelegate hintStateViewForDialog:self];
        [_modalView addSubview:v];
    }
    
    if(v==nil)//no custom subview
    {
        UILabel * label = [EMHint defaultLabelWithText:message];
        
        UIFont *ft = [UIFont fontWithName:@"Helvetica" size:17.0];
        CGSize sz = [message boundingRectWithSize:CGSizeMake(240, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:ft} context:nil].size;
        label.frame = CGRectMake(floorf(presentationPlace.center.x - sz.width/2),
                                 floorf(presentationPlace.center.y - sz.height/2),
                                 floorf(sz.width),
                                 floorf(sz.height +10));
        [label setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin
                                    | UIViewAutoresizingFlexibleRightMargin
                                    | UIViewAutoresizingFlexibleLeftMargin
                                    | UIViewAutoresizingFlexibleBottomMargin
                                    )];

        [_modalView addSubview:label];
    }
    
    if ([[self hintDelegate] respondsToSelector:@selector(hintStateHasDefaultTapGestureRecognizer:)]) {
        BOOL flag = [self.hintDelegate hintStateHasDefaultTapGestureRecognizer:self];
        if (flag) {
            [self _addTap];
        }
    } else {
        [self _addTap];
    }
    
    [UIView animateWithDuration:0.6 animations:^{
        _modalView.alpha = 1;
    }];
}

+ (UILabel*) defaultLabelWithText:(NSString*)str
{
    //label
    UIFont *ft = [UIFont boldSystemFontOfSize:17];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:ft];
    [label setText:str];
    [label setTextColor:[UIColor whiteColor]];
    [label setNumberOfLines:0];
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    
    return label;
}

@end
