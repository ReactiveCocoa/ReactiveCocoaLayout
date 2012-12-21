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

// Observes the receiver's baseline for changes.
//
// This observes the bounds of the receiver and the frame of the receiver's
// -viewForBaselineLayout, and recalculates the offset of the baseline from the
// maximum Y edge whenever either changes.
//
// Returns a signal of baseline offsets from the maximum Y edge of the view.
- (RACSignal *)rcl_baselineSignal;

@end
