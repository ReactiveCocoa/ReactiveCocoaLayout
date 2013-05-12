//
//  RCLMacros.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <ReactiveCocoa/metamacros.h>

// Binds a view's frame to a set of attributes which describe different parts of
// the frame rectangle.
//
// This macro should be used on the left side of an equal sign, and the right
// side should be an NSDictionary containing RCL layout attributes, mapped to
// the signals or constant values to bind them to.
//
// The order that attributes are specified is irrelevant because dictionaries
// are always unordered. However, because there can be implicit dependencies in
// layout calculations (e.g., aligning the right side of a rectangle requires
// knowing its final width), attributes are applied in the following order:
//
//  1. `rcl_rect`
//  2. `rcl_size`, `rcl_origin`
//  3. `rcl_width`, `rcl_height`
//  4. `rcl_center`
//  5. `rcl_centerX`, `rcl_centerY`
//  6. `rcl_left`, `rcl_top`, `rcl_right`, `rcl_bottom`, `rcl_leading`, `rcl_trailing`
//
// The relative order of attributes that have the same priority is undefined.
//
// Examples:
//
//  /*
//   * Sets the top of the view's frame to a constant 8 points, and puts the
//   * leading side of the rect after the trailing side of another view, plus
//   * 6 points of padding.
//   *
//   * The view's frame will always match its intrinsic size.
//   */
//  RCLFrame(view) = @{
//      rcl_top: @8,
//      rcl_leading: [otherView.rcl_trailingSignal plus:[RACSignal return:@6]]
//  };
//
//  /*
//   * Keeps the view at a constant 64 points wide, and centered at (100, 100).
//   *
//   * The view's height will always match its intrinsic size.
//   */
//  RCLFrame(view) = @{
//      rcl_width: @64,
//      rcl_center: MEDBox(CGPointMake(100, 100))
//  };
#define RCLFrame(VIEW) \
	[RCLRectAssignmentTrampoline trampolineWithView:(VIEW)][@"rcl_frame"]

// Like `RCLFrame`, but binds to the view's `rcl_alignmentRect` instead of its
// `rcl_frame`.
#define RCLAlignment(VIEW) \
	[RCLRectAssignmentTrampoline trampolineWithView:(VIEW)][@"rcl_alignmentRect"]

#define rcl_left @(RCLAttributeLeft)
#define rcl_right @(RCLAttributeRight)
#define rcl_top @(RCLAttributeTop)
#define rcl_bottom @(RCLAttributeBottom)
#define rcl_leading @(RCLAttributeLeading)
#define rcl_trailing @(RCLAttributeTrailing)
#define rcl_width @(RCLAttributeWidth)
#define rcl_height @(RCLAttributeHeight)
#define rcl_centerX @(RCLAttributeCenterX)
#define rcl_centerY @(RCLAttributeCenterY)
#define rcl_center @(RCLAttributeCenter)
#define rcl_rect @(RCLAttributeRect)
#define rcl_size @(RCLAttributeSize)
#define rcl_origin @(RCLAttributeOrigin)

@interface RCLRectAssignmentTrampoline : NSObject

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
+ (instancetype)trampolineWithView:(UIView *)view;
#elif TARGET_OS_MAC
+ (instancetype)trampolineWithView:(NSView *)view;
#endif

- (RACSignal *)objectForKeyedSubscript:(NSString *)property;
- (void)setObject:(NSDictionary *)attributes forKeyedSubscript:(NSString *)property;

@end

typedef enum : NSInteger {
	// Order is important here! It determines the order in which attributes are
	// applied (and overwritten) in a binding.
	RCLAttributeRect,
	RCLAttributeSize,
	RCLAttributeOrigin,
	RCLAttributeHeight,
	RCLAttributeWidth,
	RCLAttributeCenter,
	RCLAttributeCenterX,
	RCLAttributeCenterY,
	RCLAttributeBottom,
	RCLAttributeRight,
	RCLAttributeTop,
	RCLAttributeLeft,
	RCLAttributeTrailing,
	RCLAttributeLeading,
} RCLAttribute;
