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

// FIXME: These properties aren't actually declared as KVO-compliant by UIKit.
// Here be dragons?
- (RACSignal *)rcl_boundsSignal {
	return RACAbleWithStart(self.bounds);
}

- (RACSignal *)rcl_frameSignal {
	return RACAbleWithStart(self.frame);
}

- (RACSignal *)rcl_baselineSignal {
	__weak UIView *originalBaselineView = self.viewForBaselineLayout;

	@weakify(self);
	return [RACSignal combineLatest:@[ self.rcl_boundsSignal, self.viewForBaselineLayout.rcl_frameSignal ] reduce:^(NSValue *bounds, NSValue *baselineViewFrame) {
		@strongify(self);

		UIView *baselineView = self.viewForBaselineLayout;
		NSAssert([baselineView isDescendantOfView:self], @"%@ must be a descendant of %@ to be its viewForBaselineLayout", baselineView, self);
		NSAssert([baselineView isEqual:originalBaselineView], @"-viewForBaselineLayout for %@ changed from %@ to %@", self, originalBaselineView, baselineView);

		CGRect topLevelFrame = [baselineView.superview convertRect:baselineViewFrame.med_rectValue toView:self];
		return @(CGRectGetMaxY(bounds.med_rectValue) - CGRectGetMaxY(topLevelFrame));
	}];
}

- (RACSignal *)rcl_insetBaseline:(RACSignal *)rectSignal {
	NSParameterAssert(rectSignal != nil);
	return [rectSignal remainderAfterSlicingAmount:self.rcl_baselineSignal fromEdge:CGRectMinYEdge];
}

- (RACSignal *)rcl_outsetBaseline:(RACSignal *)rectSignal {
	NSParameterAssert(rectSignal != nil);
	return [rectSignal growEdge:CGRectMinYEdge byAmount:self.rcl_baselineSignal];
}

@end
