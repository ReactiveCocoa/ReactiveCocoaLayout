//
//  View+RCLAutoLayoutObservationAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-17.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

@class RACSignal;

// Extensions to UIView on iOS and NSView on OS X, depending only on
// cross-platform Auto Layout APIs.
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
@interface UIView (RCLAutoLayoutObservationAdditions)
#elif TARGET_OS_MAC
@interface NSView (RCLAutoLayoutObservationAdditions)
#endif

// Observes the receiver's `intrinsicContentSize` for changes.
//
// Returns a signal which sends the current and all future values for
// `intrinsicContentSize`.
- (RACSignal *)rcl_intrinsicContentSizeSignal;

@end
