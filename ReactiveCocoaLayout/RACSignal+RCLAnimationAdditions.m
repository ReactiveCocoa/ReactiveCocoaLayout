//
//  RACSignal+RCLAnimationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-01-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "RACSignal+RCLAnimationAdditions.h"
#import "EXTScope.h"

// The number of animated signals in the current chain.
//
// This should only be used while on the main thread.
static NSUInteger RCLSignalAnimationLevel = 0;

BOOL RCLIsInAnimatedSignal (void) {
	if (![NSThread isMainThread]) return NO;

	return RCLSignalAnimationLevel > 0;
}

#ifndef __IPHONE_OS_VERSION_MIN_REQUIRED

// The current animation stack.
//
// This should only be used while on the main thread.
static NSMutableArray *RCLSignalAnimationStack = nil;

CAAnimation * RCLCurrentAnimation(void) {
	if (![NSThread isMainThread]) return nil;

	return RCLSignalAnimationStack.lastObject;
}

// Pushes the given animation on to the animation stack.
//
// animation - The animation to push on to the stack. Cannot be nil.
//
// Returns nothing.
static void RCLPushAnimation(CAAnimation *animation) {	
	if (![NSThread isMainThread]) return;

	if (RCLSignalAnimationStack == nil) RCLSignalAnimationStack = [NSMutableArray array];
	[RCLSignalAnimationStack addObject:animation];
}

// Pops the top-most animation off the animation stack.
static void RCLPopAnimation(void) {
	if (![NSThread isMainThread]) return;

	[RCLSignalAnimationStack removeLastObject];
}

#endif

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
	return animateWithDuration(self, &duration, RCLAnimationCurveDefault);
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

#ifndef __IPHONE_OS_VERSION_MIN_REQUIRED

- (RACSignal *)animateWithAnimation:(CAAnimation *)animation {
	NSParameterAssert(animation != nil);

	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id value) {
			++RCLSignalAnimationLevel;
			@onExit {
				NSCAssert(RCLSignalAnimationLevel > 0, @"Unbalanced decrement of RCLSignalAnimationLevel");
				--RCLSignalAnimationLevel;
			};

			RCLPushAnimation(animation);
			@onExit {
				RCLPopAnimation();
			};

			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				[subscriber sendNext:value];
			} completionHandler:nil];
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}];
}

static CGSize RCLInterpolateSize(CGSize startSize, CGSize endSize, CGFloat t) {
	return CGSizeMake(startSize.width + t * (endSize.width - startSize.width), startSize.height + t * (endSize.height - startSize.height));
}

static CGPoint RCLInterpolatePoint(CGPoint startPoint, CGPoint endPoint, CGFloat t) {
	return CGPointMake(startPoint.x + t * (endPoint.x - startPoint.x), startPoint.y + t * (endPoint.y - startPoint.y));
}

static id RCLInterpolateValue(id startValue, id endValue, CGFloat t) {
	NSCAssert([startValue class] == [endValue class], @"Start value class (%@) does not match end value class (%@).", [startValue class], [endValue class]);
	
	if ([startValue isKindOfClass:NSValue.class]) {
		NSValue *start = startValue;
		NSValue *end = endValue;
		if (start.med_geometryStructType == MEDGeometryStructTypeRect) {
			CGRect startRect = start.med_rectValue;
			CGRect endRect = end.med_rectValue;
			CGPoint newPoint = RCLInterpolatePoint(startRect.origin, endRect.origin, t);
			CGSize newSize = RCLInterpolateSize(startRect.size, endRect.size, t);
			CGRect newRect = (CGRect){ .origin = newPoint, .size = newSize };
			return MEDBox(newRect);
		} else if (start.med_geometryStructType == MEDGeometryStructTypeSize) {
			return MEDBox(RCLInterpolateSize(start.med_sizeValue, end.med_sizeValue, t));
		} else if (start.med_geometryStructType == MEDGeometryStructTypePoint) {
			return MEDBox(RCLInterpolatePoint(start.med_pointValue, end.med_pointValue, t));
		} else {
			NSCAssert(NO, @"%@ is of an unhandled type (%@).", startValue, [startValue class]);
		}
	} else if ([startValue isKindOfClass:NSNumber.class]) {
		NSNumber *start = startValue;
		NSNumber *end = endValue;
		return @(start.doubleValue + t * (end.doubleValue - start.doubleValue));
	} else {
		NSCAssert(NO, @"%@ is of an unhandled type (%@).", startValue, [startValue class]);
	}

	return nil;
}

RCLInterpolationBlock RCLBounceInterpolation(void) {
	return ^(CGFloat progress) {
		CGFloat zeta = 0.33;
		CGFloat omega = 20.0;
		CGFloat beta = sqrt(1 - zeta * zeta);
		CGFloat phi = atan(beta / zeta);
		return 1.0 + -1.0 / beta * exp(-zeta * omega * progress) * sin(beta * omega * progress + phi);
	};
}

- (RACSignal *)animateWithDuration:(NSTimeInterval)duration start:(id)start interpolate:(RCLInterpolationBlock)interpolate {
	NSParameterAssert(start != nil);
	NSParameterAssert(interpolate != NULL);

	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		__block id lastValue = start;
		return [self subscribeNext:^(id value) {
			CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];

			const NSUInteger stepCount = (NSUInteger)ceil(60 * duration);
			NSMutableArray *steps = [NSMutableArray arrayWithCapacity:stepCount];
			for (NSUInteger i = 0; i < stepCount; i++) {
				CGFloat progress = i / (CGFloat)stepCount;
				CGFloat t = interpolate(progress);
				[steps addObject:RCLInterpolateValue(lastValue, value, t)];
			}

			animation.values = steps;
			animation.duration = duration;

			++RCLSignalAnimationLevel;
			@onExit {
				NSCAssert(RCLSignalAnimationLevel > 0, @"Unbalanced decrement of RCLSignalAnimationLevel");
				--RCLSignalAnimationLevel;
			};

			RCLPushAnimation(animation);
			@onExit {
				RCLPopAnimation();
			};

			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				[subscriber sendNext:value];
			} completionHandler:nil];

			lastValue = value;
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}];
}

#endif

@end
