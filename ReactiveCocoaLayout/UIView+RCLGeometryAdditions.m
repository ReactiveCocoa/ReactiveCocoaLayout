//
//  UIView+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "UIView+RCLGeometryAdditions.h"
#import "RACSignal+RCLGeometryAdditions.h"

// Returns a signal which sends the offset of the baseline from the view's
// bottom.
static RACSignal *baselineOffsetSignal(UIView *view) {
	return [view.rcl_boundsSignal map:^(NSValue *bounds) {
		UIView *baselineView = view.viewForBaselineLayout;
		NSCAssert([baselineView isDescendantOfView:view], @"%@ must be a descendant of %@ to be its viewForBaselineLayout", baselineView, view);

		CGRect topLevelFrame = [baselineView.superview convertRect:baselineView.frame toView:view];
		return @(CGRectGetMaxY(bounds.med_rectValue) - CGRectGetMaxY(topLevelFrame));
	}];
}

@implementation UIView (RCLGeometryAdditions)

// FIXME: These properties aren't actually declared as KVO-compliant by UIKit.
// Here be dragons?
- (RACSignal *)rcl_boundsSignal {
	return RACAbleWithStart(self.bounds);
}

- (RACSignal *)rcl_frameSignal {
	return RACAbleWithStart(self.frame);
}

- (RACSignal *)rcl_insetBaseline:(RACSignal *)rectSignal {
	NSParameterAssert(rectSignal != nil);

	return [rectSignal remainderAfterSlicingAmount:baselineOffsetSignal(self) fromEdge:CGRectMinYEdge];
}

- (RACSignal *)rcl_outsetBaseline:(RACSignal *)rectSignal {
	NSParameterAssert(rectSignal != nil);

	return [rectSignal growEdge:CGRectMinYEdge byAmount:baselineOffsetSignal(self)];
}

@end
