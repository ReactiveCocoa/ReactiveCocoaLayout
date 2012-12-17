//
//  UIView+RCLObservationAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCLSignal;

@interface UIView (RCLObservationAdditions)

// Observes the receiver's `bounds` for changes.
//
// Returns a signal which sends the current and all future values for `bounds`.
- (id<RCLSignal>)rcl_boundsSignal;

// Observes the receiver's `frame` for changes.
//
// Returns a signal which sends the current and all future values for `frame`.
- (id<RCLSignal>)rcl_frameSignal;

// Observes the receiver's `intrinsicContentSize` for changes.
//
// Returns a signal which sends the current and all future values for
// `intrinsicContentSize`.
- (id<RCLSignal>)rcl_intrinsicContentSizeSignal;

@end
