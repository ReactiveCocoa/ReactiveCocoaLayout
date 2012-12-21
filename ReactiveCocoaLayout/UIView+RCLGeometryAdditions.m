//
//  UIView+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "UIView+RCLGeometryAdditions.h"
#import "EXTScope.h"
#import "RACSignal+RCLGeometryAdditions.h"

@implementation UIView (RCLGeometryAdditions)

// FIXME: These properties aren't actually declared as KVO-compliant by Core
// Animation. Here be dragons?
- (RACSignal *)rcl_boundsSignal {
	@weakify(self);

	return [[RACAbleWithStart(self.layer.bounds)
		map:^(id _) {
			@strongify(self);
			return MEDBox(self.bounds);
		}]
		distinctUntilChanged];
}

- (RACSignal *)rcl_frameSignal {
	@weakify(self);

	return [[[RACSignal merge:@[ self.rcl_boundsSignal, RACAbleWithStart(self.layer.position) ]]
		map:^(id _) {
			@strongify(self);
			return MEDBox(self.frame);
		}]
		distinctUntilChanged];
}

- (RACSignal *)rcl_baselineSignal {
	if (self.viewForBaselineLayout == self) {
		// The baseline will always be the bottom of our bounds.
		return [RACSignal return:@0];
	}

	@weakify(self);
	return [[RACSignal
		merge:@[ self.rcl_boundsSignal, self.rcl_frameSignal, self.viewForBaselineLayout.rcl_frameSignal ]]
		map:^(id _) {
			@strongify(self);

			UIView *baselineView = self.viewForBaselineLayout;
			NSAssert([baselineView.superview isEqual:self], @"%@ must be a subview of %@ to be its viewForBaselineLayout", baselineView, self);

			return @(CGRectGetHeight(self.bounds) - CGRectGetMaxY(baselineView.frame));
		}].distinctUntilChanged;
}

@end
