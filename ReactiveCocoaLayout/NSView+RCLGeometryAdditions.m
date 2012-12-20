//
//  NSView+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSView+RCLGeometryAdditions.h"
#import "NSNotificationCenter+RACSupport.h"
#import "RACSignal+RCLGeometryAdditions.h"

@implementation NSView (RCLGeometryAdditions)

- (RACSignal *)rcl_boundsSignal {
	// TODO: This only needs to be enabled when we actually start watching for
	// the notification (i.e., after the startWith:).
	self.postsBoundsChangedNotifications = YES;
	return [[[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewBoundsDidChangeNotification object:self]
		map:^(NSNotification *notification) {
			NSView *view = notification.object;
			return [NSValue valueWithRect:view.bounds];
		}]
		startWith:[NSValue valueWithRect:self.bounds]];
}

- (RACSignal *)rcl_frameSignal {
	// TODO: This only needs to be enabled when we actually start watching for
	// the notification (i.e., after the startWith:).
	self.postsFrameChangedNotifications = YES;
	return [[[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewFrameDidChangeNotification object:self]
		map:^(NSNotification *notification) {
			NSView *view = notification.object;
			return [NSValue valueWithRect:view.frame];
		}]
		startWith:[NSValue valueWithRect:self.frame]];
}

- (RACSignal *)rcl_baselineSignal {
	return [RACSignal return:@(self.baselineOffsetFromBottom)];
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
