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

// Sends the receiver's -baselineOffsetFromBottom.
//
// This is mostly useful for code compatibility with -[UIView
// rcl_baselineSignal].
//
// Returns a signal which sends the value returned from
// -baselineOffsetFromBottom and then completes.
- (RACSignal *)rcl_baselineSignal;

// Trims the minimum Y edge of each CGRect in the given signal, removing the
// part of the rect that would lie below the baseline in the receiver (i.e., the
// space for any descenders).
//
// Returns a signal of adjusted CGRect values.
- (RACSignal *)rcl_insetBaseline:(RACSignal *)rectSignal;

// Grows the minimum Y edge of each CGRect in the given signal, adding space for
// descenders based on the receiver's -baselineOffsetFromBottom method.
//
// Returns a signal of adjusted CGRect values.
- (RACSignal *)rcl_outsetBaseline:(RACSignal *)rectSignal;

@end
