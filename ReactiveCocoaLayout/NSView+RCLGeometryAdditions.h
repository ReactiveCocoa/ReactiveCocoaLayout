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
// alignment rect matches the new value. If set from within an animated signal,
// the receiver's -animator proxy is automatically used.
//
// This property may have `RAC()` bindings applied to it, but it is not
// KVO-compliant. Use -rcl_alignmentRectSignal for observing changes instead.
@property (nonatomic, assign) CGRect rcl_alignmentRect;

// The receiver's current frame.
//
// If set from within an animated signal, the receiver's -animator proxy is
// automatically used.
//
// This property may have `RAC()` bindings applied to it, but it is not
// KVO-compliant. Use -rcl_frameSignal for observing changes instead.
@property (nonatomic, assign) CGRect rcl_frame;

// The receiver's current bounds.
//
// If set from within an animated signal, the receiver's -animator proxy is
// automatically used.
//
// This property may have `RAC()` bindings applied to it, but it is not
// KVO-compliant. Use -rcl_boundsSignal for observing changes instead.
@property (nonatomic, assign) CGRect rcl_bounds;

// Whether the receiver is marked as being hidden.
//
// This property is mostly for the convenience of bindings (because -isHidden
// does not work in a key path), and may have `RAC()` applied to it, but it is
// not KVO-compliant.
@property (nonatomic, assign, getter = rcl_isHidden) BOOL rcl_hidden;

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
