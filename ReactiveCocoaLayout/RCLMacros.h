//
//  RCLMacros.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <ReactiveCocoa/metamacros.h>

#define RCLFrame(VIEW) \
	[RCLRectAssignmentTrampoline trampolineWithView:(VIEW)][@"rcl_frame"]

#define RCLBounds(VIEW) \
	[RCLRectAssignmentTrampoline trampolineWithView:(VIEW)][@"rcl_bounds"]

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
	RCLAttributeHeight,
	RCLAttributeWidth,
	RCLAttributeOrigin,
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
