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

#define rcl_left @(NSLayoutAttributeLeft)
#define rcl_right @(NSLayoutAttributeRight)
#define rcl_top @(NSLayoutAttributeTop)
#define rcl_bottom @(NSLayoutAttributeBottom)
#define rcl_width @(NSLayoutAttributeWidth)
#define rcl_height @(NSLayoutAttributeHeight)

@interface RCLRectAssignmentTrampoline : NSObject

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
+ (instancetype)trampolineWithView:(UIView *)view;
#elif TARGET_OS_MAC
+ (instancetype)trampolineWithView:(NSView *)view;
#endif

- (RACSignal *)objectForKeyedSubscript:(NSString *)property;
- (void)setObject:(NSDictionary *)attributes forKeyedSubscript:(NSString *)property;

@end
