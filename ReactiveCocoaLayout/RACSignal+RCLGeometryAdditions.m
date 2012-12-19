//
//  RACSignal+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RACSignal+RCLGeometryAdditions.h"

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

	return (id)[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id value) {
			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				[UIView animateWithDuration:duration delay:0 options:options animations:^{
					[subscriber sendNext:value];
				} completion:NULL];
			#elif TARGET_OS_MAC
				[NSAnimationContext beginGrouping];
				if (hasDuration) NSAnimationContext.currentContext.duration = duration;

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

// When any signal sends an NSNumber, if -compare: invoked against the previous
// value (and passed the new value) returns `result`, the new value is sent on
// the returned signal.
static RACSignal *latestNumberMatchingComparisonResult(NSArray *signals, NSComparisonResult result) {
	NSCParameterAssert(signals != nil);

	return [[[RACSignal merge:signals]
		scanWithStart:nil combine:^(NSNumber *previous, NSNumber *next) {
			if (previous == nil) return next;
			if (next == nil) return previous;

			if ([previous compare:next] == result) {
				return next;
			} else {
				return previous;
			}
		}]
		filter:^ BOOL (NSNumber *value) {
			return value != nil;
		}];
}

@implementation RACSignal (RCLGeometryAdditions)

+ (RACSignal *)rectsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal width:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	return [RACSignal combineLatest:@[ xSignal, ySignal, widthSignal, heightSignal ] reduce:^(NSNumber *x, NSNumber *y, NSNumber *width, NSNumber *height) {
		return MEDBox(CGRectMake(x.doubleValue, y.doubleValue, width.doubleValue, height.doubleValue));
	}];
}

+ (RACSignal *)rectsWithOrigin:(RACSignal *)originSignal size:(RACSignal *)sizeSignal {
	NSParameterAssert(originSignal != nil);
	NSParameterAssert(sizeSignal != nil);

	return [RACSignal combineLatest:@[ originSignal, sizeSignal ] reduce:^(NSValue *origin, NSValue *size) {
		CGPoint p = origin.med_pointValue;
		CGSize s = size.med_sizeValue;

		return MEDBox(CGRectMake(p.x, p.y, s.width, s.height));
	}];
}

- (RACSignal *)size {
	return [self map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.size);
	}];
}

+ (RACSignal *)sizesWithWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	return [RACSignal combineLatest:@[ widthSignal, heightSignal ] reduce:^(NSNumber *width, NSNumber *height) {
		return MEDBox(CGSizeMake(width.doubleValue, height.doubleValue));
	}];
}

- (RACSignal *)width {
	return [self map:^(NSValue *value) {
		return @(value.med_sizeValue.width);
	}];
}

- (RACSignal *)height {
	return [self map:^(NSValue *value) {
		return @(value.med_sizeValue.height);
	}];
}

- (RACSignal *)origin {
	return [self map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.origin);
	}];
}

+ (RACSignal *)pointsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);

	return [RACSignal combineLatest:@[ xSignal, ySignal ] reduce:^(NSNumber *x, NSNumber *y) {
		return MEDBox(CGPointMake(x.doubleValue, y.doubleValue));
	}];
}

- (RACSignal *)x {
	return [self map:^(NSValue *value) {
		return @(value.med_pointValue.x);
	}];
}

- (RACSignal *)y {
	return [self map:^(NSValue *value) {
		return @(value.med_pointValue.y);
	}];
}

- (RACSignal *)insetWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	// Subscribe to self last so that we don't skip any values sent
	// immediately. See https://github.com/github/ReactiveCocoa/issues/192.
	return [RACSignal combineLatest:@[ widthSignal, heightSignal, self ] reduce:^(NSNumber *width, NSNumber *height, NSValue *rect) {
		return MEDBox(CGRectInset(rect.med_rectValue, width.doubleValue, height.doubleValue));
	}];
}

- (RACSignal *)sliceWithAmount:(RACSignal *)amountSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		return MEDBox(CGRectSlice(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (RACSignal *)remainderAfterSlicingAmount:(RACSignal *)amountSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		return MEDBox(CGRectRemainder(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal fromEdge:(CGRectEdge)edge {
	return [self divideWithAmount:sliceAmountSignal padding:[RACSignal return:@0] fromEdge:edge];
}

- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal padding:(RACSignal *)paddingSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(sliceAmountSignal != nil);
	NSParameterAssert(paddingSignal != nil);

	RACSignal *amountPlusPadding = [RACSignal combineLatest:@[ sliceAmountSignal, paddingSignal ] reduce:^(NSNumber *amount, NSNumber *padding) {
		return @(amount.doubleValue + padding.doubleValue);
	}];

	RACSignal *sliceSignal = [self sliceWithAmount:sliceAmountSignal fromEdge:edge];
	RACSignal *remainderSignal = [self remainderAfterSlicingAmount:amountPlusPadding fromEdge:edge];

	return [RACTuple tupleWithObjects:sliceSignal, remainderSignal, nil];
}

+ (RACSignal *)max:(NSArray *)signals {
	return latestNumberMatchingComparisonResult(signals, NSOrderedAscending);
}

+ (RACSignal *)min:(NSArray *)signals {
	return latestNumberMatchingComparisonResult(signals, NSOrderedDescending);
}

- (RACSignal *)animate {
	return animateWithDuration(self, NULL, RCLAnimationCurveDefault);
}

- (RACSignal *)animateWithDuration:(NSTimeInterval)duration {
	return [self animateWithDuration:duration curve:RCLAnimationCurveDefault];
}

- (RACSignal *)animateWithDuration:(NSTimeInterval)duration curve:(RCLAnimationCurve)curve {
	return animateWithDuration(self, &duration, RCLAnimationCurveDefault);
}

@end
