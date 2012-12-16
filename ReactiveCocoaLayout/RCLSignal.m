//
//  RCLSignal.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RCLSignal.h"

// Animates the given signal.
//
// self        - The signal to animate.
// durationPtr - If not NULL, an explicit duration to specify when starting the
//				 animation.
// curve       - The animation curve to use.
static id<RCLSignal> animateWithDuration (id<RCLSignal> self, NSTimeInterval *durationPtr, RCLAnimationCurve curve) {
	return (id)[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id value) {
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

				[UIView animateWithDuration:duration delay:0 options:options animations:^{
					[subscriber sendNext:value];
				} completion:NULL];
			#elif TARGET_OS_MAC
				[NSAnimationContext beginGrouping];
				if (durationPtr != NULL) NSAnimationContext.currentContext.duration = *durationPtr;

				switch (curve) {
					case RCLAnimationCurveEaseInOut:
						NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
						break;

					case RCLAnimationCurveEaseIn:
						NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
						break;

					case RCLAnimationCurveEaseOut:
						NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
						break;

					case RCLAnimationCurveLinear:
						NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
						break;

					case RCLAnimationCurveDefault:
						break;

					default:
						NSCAssert(NO, @"Unrecognized animation curve: %i", (int)curve);
				}

				[subscriber sendNext:value];
				[NSAnimationContext endGrouping];
			#endif
		} error:^(NSError *error) {
			[subscriber sendError:error];
		} completed:^{
			[subscriber sendCompleted];
		}];
	}];
}

@concreteprotocol(RCLSignal)

#pragma mark RACStream

+ (instancetype)empty {
	return nil;
}

+ (instancetype)return:(id)value {
	return nil;
}

- (instancetype)bind:(id (^)(id value))block {
	return nil;
}

- (instancetype)concat:(id<RACStream>)stream {
	return nil;
}

- (instancetype)flatten {
	return nil;
}

+ (instancetype)zip:(NSArray *)streams reduce:(id)reduceBlock {
	return nil;
}

#pragma mark RCLSignal

- (id<RCLSignal>)size {
	return [self map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.size);
	}];
}

- (id<RCLSignal>)origin {
	return [self map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.origin);
	}];
}

- (id<RCLSignal>)width {
	return [self map:^(NSValue *value) {
		return @(value.med_sizeValue.width);
	}];
}

- (id<RCLSignal>)height {
	return [self map:^(NSValue *value) {
		return @(value.med_sizeValue.height);
	}];
}

- (id<RCLSignal>)x {
	return [self map:^(NSValue *value) {
		return @(value.med_pointValue.x);
	}];
}

- (id<RCLSignal>)y {
	return [self map:^(NSValue *value) {
		return @(value.med_pointValue.y);
	}];
}

- (id<RCLSignal>)insetWidth:(CGFloat)width height:(CGFloat)height {
	return [self map:^(NSValue *value) {
		return MEDBox(CGRectInset(value.med_rectValue, width, height));
	}];
}

- (id<RCLSignal>)sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return MEDBox(CGRectSlice(value.med_rectValue, amount, edge));
	}];
}

- (id<RCLSignal>)remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return MEDBox(CGRectRemainder(value.med_rectValue, amount, edge));
	}];
}

- (RACTuple *)divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self divideWithAmount:amount padding:0 fromEdge:edge];
}

- (RACTuple *)divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge {
	return [RACTuple tupleWithObjects:[self sliceWithAmount:amount fromEdge:edge], [self remainderWithAmount:fmax(0, amount + padding) fromEdge:edge], nil];
}

- (id<RCLSignal>)animate {
	return animateWithDuration(self, NULL, RCLAnimationCurveDefault);
}

- (id<RCLSignal>)animateWithDuration:(NSTimeInterval)duration {
	return [self animateWithDuration:duration curve:RCLAnimationCurveDefault];
}

- (id<RCLSignal>)animateWithDuration:(NSTimeInterval)duration curve:(RCLAnimationCurve)curve {
	return animateWithDuration(self, &duration, RCLAnimationCurveDefault);
}

@end
