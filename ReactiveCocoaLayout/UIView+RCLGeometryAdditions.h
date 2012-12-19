//
//  UIView+RCLGeometryAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (RCLGeometryAdditions)

// Observes the receiver's `bounds` for changes.
//
// Returns a signal which sends the current and all future values for `bounds`.
- (RACSignal *)rcl_boundsSignal;

// Observes the receiver's `frame` for changes.
//
// Returns a signal which sends the current and all future values for `frame`.
- (RACSignal *)rcl_frameSignal;

// Trims the maximum Y edge of each CGRect in the given signal, removing the
// part of the rect that would lie below the baseline in the receiver (i.e., the
// space for any descenders).
//
// Returns a signal of adjusted CGRect values.
- (RACSignal *)rcl_insetBaseline:(RACSignal *)rectSignal;

// Grows the maximum Y edge of each CGRect in the given signal, adding space for
// descenders based on the receiver's -baselineOffsetFromBottom method.
//
// Returns a signal of adjusted CGRect values.
- (RACSignal *)rcl_outsetBaseline:(RACSignal *)rectSignal;

@end
