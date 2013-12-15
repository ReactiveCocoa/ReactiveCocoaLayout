//
//  UIViewController+RCLPresentationAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-12-15.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACSignal;

@interface UIViewController (RCLPresentationAdditions)

// Presents a view controller.
//
// Returns a signal which will send completed after -viewDidAppear: has been
// invoked on the presented view controller.
- (RACSignal *)rcl_presentViewController:(UIViewController *)viewController animated:(BOOL)animated;

// Dismisses the view controller that was presented by the receiver.
//
// Returns a signal which will send completed after -viewDidDisappear: has been
// invoked on the presented view controller.
- (RACSignal *)rcl_dismissViewControllerAnimated:(BOOL)animated;

@end
