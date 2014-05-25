//
//  UIViewController+RCLPresentationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-12-15.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "UIViewController+RCLPresentationAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation UIViewController (RCLPresentationAdditions)

- (RACSignal *)rcl_presentViewController:(UIViewController *)viewController animated:(BOOL)animated {
	return [[RACSignal
		create:^(id<RACSubscriber> subscriber) {
			[self presentViewController:viewController animated:animated completion:^{
				[subscriber sendCompleted];
			}];
		}]
		setNameWithFormat:@"%@ -rcl_presentViewController: %@ animated: %i", self, viewController, (int)animated];
}

- (RACSignal *)rcl_dismissViewControllerAnimated:(BOOL)animated {
	return [[RACSignal
		create:^(id<RACSubscriber> subscriber) {
			[self dismissViewControllerAnimated:animated completion:^{
				[subscriber sendCompleted];
			}];
		}]
		setNameWithFormat:@"%@ -rcl_dismissViewControllerAnimated: %i", self, (int)animated];
}

@end
