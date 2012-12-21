//
//  NSView+RCLGeometryAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (RCLGeometryAdditions)

// The alignment rect for the receiver's current frame.
//
// Setting this property will adjust the receiver's frame such that the
// alignment rect matches the new value.
//
// This property may have `RAC()` bindings applied to it, but it is not
// KVO-compliant. Use -rcl_alignmentRectSignal for observing changes instead.
@property (nonatomic, assign) CGRect rcl_alignmentRect;

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
