//
//  NSView+RCLGeometryAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (RCLGeometryAdditions)

// Observes the receiver's `bounds` for changes.
//
// This method may enable `postsBoundsChangedNotifications` to ensure that
// changes are received.
//
// Returns a signal which sends the current and all future values for `bounds`.
- (RACSignal *)rcl_boundsSignal;

// Observes the receiver's `frame` for changes.
//
// This method may enable `postsFrameChangedNotifications` to ensure that
// changes are received.
//
// Returns a signal which sends the current and all future values for `frame`.
- (RACSignal *)rcl_frameSignal;

// Sends the receiver's baseline, relative to the minimum Y edge.
//
// Returns a signal of baseline offsets from the minimum Y edge of the receiver.
- (RACSignal *)rcl_baselineSignal;

@end
