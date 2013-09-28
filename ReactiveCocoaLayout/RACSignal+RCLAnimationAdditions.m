//
//  RACSignal+RCLAnimationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-01-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "RACSignal+RCLAnimationAdditions.h"
#import <libkern/OSAtomic.h>
#import <ReactiveCocoa/RACEXTScope.h>

// The number of animated signals in the current chain.
//
// This should only be used while on the main thread.
static NSUInteger RCLSignalAnimationLevel = 0;

BOOL RCLIsInAnimatedSignal (void) {
	if (![NSThread isMainThread]) return NO;

	return RCLSignalAnimationLevel > 0;
}

// Animates the given signal.
//
// self        - The signal to animate.
// durationPtr - If not NULL, an explicit duration to specify when starting the
//				 animation.
// curve       - The animation curve to use.
static RACSignal *animateWithDuration (RACSignal *self, NSTimeInterval *durationPtr, RCLAnimationCurve curve) {
	#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
		// This seems like a saner default setting for a layout-triggered
		// animation.
		UIViewAnimationOptions options = curve | UIViewAnimationOptionLayoutSubviews;
		if (curve != RCLAnimationCurveDefault) options |= UIViewAnimationOptionOverrideInheritedCurve;

		NSTimeInterval duration = 0.2;
		if (durationPtr != NULL) {
			duration = *durationPtr;
			options |= UIViewAnimationOptionOverrideInheritedDuration;
		}
	#elif TARGET_OS_MAC
		BOOL hasDuration = (durationPtr != NULL);
		NSTimeInterval duration = (hasDuration ? *durationPtr : 0);
	#endif

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id value) {
			++RCLSignalAnimationLevel;
			@onExit {
				NSCAssert(RCLSignalAnimationLevel > 0, @"Unbalanced decrement of RCLSignalAnimationLevel");
				--RCLSignalAnimationLevel;
			};

			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				[UIView animateWithDuration:duration delay:0 options:options animations:^{
					[subscriber sendNext:value];
				} completion:nil];
			#elif TARGET_OS_MAC
				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					if (hasDuration) context.duration = duration;

					switch (curve) {
						case RCLAnimationCurveEaseInOut:
							context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
							break;

						case RCLAnimationCurveEaseIn:
							context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
							break;

						case RCLAnimationCurveEaseOut:
							context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
							break;

						case RCLAnimationCurveLinear:
							context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
							break;

						case RCLAnimationCurveDefault:
							break;

						default:
							NSCAssert(NO, @"Unrecognized animation curve: %i", (int)curve);
					}

					[subscriber sendNext:value];
				} completionHandler:nil];
			#endif
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -animateWithDuration: %f curve: %li", self.name, (double)duration, (long)curve];
}

@implementation RACSignal (RCLAnimationAdditions)

- (RACSignal *)animate {
	return animateWithDuration(self, NULL, RCLAnimationCurveDefault);
}

- (RACSignal *)animateWithDuration:(NSTimeInterval)duration {
	return [self animateWithDuration:duration curve:RCLAnimationCurveDefault];
}

- (RACSignal *)animateWithDuration:(NSTimeInterval)duration curve:(RCLAnimationCurve)curve {
	return animateWithDuration(self, &duration, curve);
}

- (RACSignal *)doAnimationCompleted:(void (^)(id))block {
	NSParameterAssert(block != nil);

	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			void (^completionBlock)(void) = ^{
				block(x);
			};

			if (!RCLIsInAnimatedSignal()) {
				completionBlock();
				return;
			}

			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				[CATransaction begin];
				CATransaction.completionBlock = completionBlock;
				[subscriber sendNext:x];
				[CATransaction commit];
			#elif TARGET_OS_MAC
				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					[subscriber sendNext:x];
				} completionHandler:completionBlock];
			#endif
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}] setNameWithFormat:@"[%@] -doAnimationCompleted:", self.name];
}

- (RACSignal *)completeAfterAnimations {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		__block volatile int32_t animating = 0;
		__block volatile uint32_t completed = 0;
		return [self subscribeNext:^(id x) {
			void (^completionBlock)(void) = ^{
				if (completed == 1) {
					[subscriber sendCompleted];
				}

				OSAtomicDecrement32Barrier(&animating);
			};

			OSAtomicIncrement32Barrier(&animating);

			if (!RCLIsInAnimatedSignal()) {
				completionBlock();
				return;
			}

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
			[CATransaction begin];
			CATransaction.completionBlock = completionBlock;
			[subscriber sendNext:x];
			[CATransaction commit];
#elif TARGET_OS_MAC
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				[subscriber sendNext:x];
			} completionHandler:completionBlock];
#endif
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			OSAtomicOr32Barrier(1, &completed);
			if (animating == 0) {
				[subscriber sendCompleted];
			}
		}];
	}] setNameWithFormat:@"[%@] -completeWithAnimation", self.name];
}

@end
