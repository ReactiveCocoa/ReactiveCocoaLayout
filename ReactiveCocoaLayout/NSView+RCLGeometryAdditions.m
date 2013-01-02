//
//  NSView+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSView+RCLGeometryAdditions.h"
#import "EXTScope.h"
#import "NSNotificationCenter+RACSupport.h"
#import "RACSignal+RCLGeometryAdditions.h"

@implementation NSView (RCLGeometryAdditions)

#pragma mark Properties

- (CGRect)rcl_alignmentRect {
	return [self alignmentRectForFrame:self.frame];
}

- (void)setRcl_alignmentRect:(CGRect)rect {
	self.rcl_frame = [self frameForAlignmentRect:rect];
}

- (CGRect)rcl_frame {
	return self.frame;
}

- (void)setRcl_frame:(CGRect)frame {
	if (self.superview != nil && self.window != nil) {
		// Matches the behavior of CGRectFloor().
		NSAlignmentOptions options = NSAlignMinXOutward | NSAlignMinYInward | NSAlignWidthInward | NSAlignHeightInward;

		CGRect windowFrame = [self.superview convertRect:frame toView:nil];
		CGRect alignedWindowFrame = [self backingAlignedRect:windowFrame options:options];
		frame = [self.superview convertRect:alignedWindowFrame fromView:nil];
	}

	if (RCLIsInAnimatedSignal()) {
		[self.animator setFrame:frame];
	} else {
		self.frame = frame;
	}
}

- (CGRect)rcl_bounds {
	return self.bounds;
}

- (void)setRcl_bounds:(CGRect)bounds {
	if (self.window != nil) {
		// Matches the behavior of CGRectFloor().
		NSAlignmentOptions options = NSAlignMinXOutward | NSAlignMinYInward | NSAlignWidthInward | NSAlignHeightInward;

		CGRect windowRect = [self convertRect:bounds toView:nil];
		CGRect alignedWindowRect = [self backingAlignedRect:windowRect options:options];
		bounds = [self convertRect:alignedWindowRect fromView:nil];
	}

	if (RCLIsInAnimatedSignal()) {
		[self.animator setBounds:bounds];
	} else {
		self.bounds = bounds;
	}
}

- (CGFloat)rcl_alphaValue {
	return self.alphaValue;
}

- (void)setRcl_alphaValue:(CGFloat)alphaValue {
	if (RCLIsInAnimatedSignal()) {
		[self.animator setAlphaValue:alphaValue];
	} else {
		self.alphaValue = alphaValue;
	}
}

- (BOOL)rcl_isHidden {
	return [self isHidden];
}

- (void)setRcl_hidden:(BOOL)hidden {
	self.hidden = hidden;
}

#pragma mark Signals

- (RACSignal *)rcl_boundsSignal {
	// TODO: These only need to be enabled when we actually start watching for
	// the notifications (i.e., after the startWith:).
	self.postsBoundsChangedNotifications = YES;
	self.postsFrameChangedNotifications = YES;

	NSArray *signals = @[
		[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewBoundsDidChangeNotification object:self],
		[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewFrameDidChangeNotification object:self]
	];

	RACSignal *signal = [[[[RACSignal merge:signals]
		map:^(NSNotification *notification) {
			NSView *view = notification.object;
			return [NSValue valueWithRect:view.bounds];
		}]
		startWith:[NSValue valueWithRect:self.bounds]]
		distinctUntilChanged];
	
	signal.name = [NSString stringWithFormat:@"%@ -rcl_boundsSignal", self];
	return signal;
}

- (RACSignal *)rcl_frameSignal {
	// TODO: This only needs to be enabled when we actually start watching for
	// the notification (i.e., after the startWith:).
	self.postsFrameChangedNotifications = YES;

	RACSignal *signal = [[[[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewFrameDidChangeNotification object:self]
		map:^(NSNotification *notification) {
			NSView *view = notification.object;
			return [NSValue valueWithRect:view.frame];
		}]
		startWith:[NSValue valueWithRect:self.frame]]
		distinctUntilChanged];
	
	signal.name = [NSString stringWithFormat:@"%@ -rcl_frameSignal", self];
	return signal;
}

- (RACSignal *)rcl_baselineSignal {
	RACSignal *signal = [RACSignal return:@(self.baselineOffsetFromBottom)];
	signal.name = [NSString stringWithFormat:@"%@ -rcl_baselineSignal", self];
	return signal;
}

@end
