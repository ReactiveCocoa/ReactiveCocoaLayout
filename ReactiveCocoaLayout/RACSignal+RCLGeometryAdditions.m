//
//  RACSignal+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RACSignal+RCLGeometryAdditions.h"
#import "EXTScope.h"
#import "RACSignal+RCLWritingDirectionAdditions.h"

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

	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id value) {
			++RCLSignalAnimationLevel;
			@onExit {
				NSCAssert(RCLSignalAnimationLevel > 0, @"Unbalanced decrement of RCLSignalAnimationLevel");
				--RCLSignalAnimationLevel;
			};

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

			NSCAssert([next isKindOfClass:NSNumber.class], @"Value sent is not a number: %@", next);

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

// A binary operator accepting two numbers and returning a number.
typedef CGFloat (^RCLBinaryOperator)(CGFloat, CGFloat);

// Used from combineSignalsWithOperator() to combine two numbers using an
// arbitrary binary operator.
static NSNumber *combineNumbersWithOperator(NSNumber *a, NSNumber *b, RCLBinaryOperator operator) {
	NSCAssert([a isKindOfClass:NSNumber.class], @"Expected a number, not %@", a);
	NSCAssert([b isKindOfClass:NSNumber.class], @"Expected a number, not %@", b);

	return @(operator(a.doubleValue, b.doubleValue));
}

// Used from combineSignalsWithOperator() to combine two values using an
// arbitrary binary operator.
static NSValue *combineValuesWithOperator(NSValue *a, NSValue *b, RCLBinaryOperator operator) {
	NSCAssert([a isKindOfClass:NSValue.class], @"Expected a value, not %@", a);
	NSCAssert([b isKindOfClass:NSValue.class], @"Expected a value, not %@", b);
	NSCAssert(a.med_geometryStructType == b.med_geometryStructType, @"Values do not contain the same type of geometry structure: %@, %@", a, b);

	switch (a.med_geometryStructType) {
		case MEDGeometryStructTypePoint: {
			CGPoint pointA = a.med_pointValue;
			CGPoint pointB = b.med_pointValue;

			CGPoint result = CGPointMake(operator(pointA.x, pointB.x), operator(pointA.y, pointB.y));
			return MEDBox(result);
		}

		case MEDGeometryStructTypeSize: {
			CGSize sizeA = a.med_sizeValue;
			CGSize sizeB = b.med_sizeValue;

			CGSize result = CGSizeMake(operator(sizeA.width, sizeB.width), operator(sizeA.height, sizeB.height));
			return MEDBox(result);
		}

		case MEDGeometryStructTypeRect:
		default:
			NSCAssert(NO, @"Values must contain CGSizes or CGPoints: %@, %@", a, b);
			return nil;
	}
}

// Combines the values of the given signals using the given binary operator,
// applied left-to-right across the signal values.
//
// The values may be CGFloats, CGSizes, or CGPoints, but all signals must send
// values of the same type.
//
// Returns a signal of results, using the same type as the input values.
static RACSignal *combineSignalsWithOperator(NSArray *signals, RCLBinaryOperator operator) {
	NSCParameterAssert(signals != nil);
	NSCParameterAssert(signals.count > 0);
	NSCParameterAssert(operator != nil);

	return [[[RACSignal combineLatest:signals]
		map:^(RACTuple *values) {
			return values.allObjects.rac_sequence;
		}]
		map:^(RACSequence *values) {
			id result = values.head;
			BOOL isNumber = [result isKindOfClass:NSNumber.class];

			for (id value in values.tail) {
				if (isNumber) {
					result = combineNumbersWithOperator(result, value, operator);
				} else {
					result = combineValuesWithOperator(result, value, operator);
				}
			}

			return result;
		}];
}

@implementation RACSignal (RCLGeometryAdditions)

+ (RACSignal *)rectsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal width:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	return [RACSignal combineLatest:@[ xSignal, ySignal, widthSignal, heightSignal ] reduce:^(NSNumber *x, NSNumber *y, NSNumber *width, NSNumber *height) {
		NSAssert([x isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", xSignal, x);
		NSAssert([y isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", ySignal, y);
		NSAssert([width isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", widthSignal, width);
		NSAssert([height isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", heightSignal, height);

		return MEDBox(CGRectMake(x.doubleValue, y.doubleValue, width.doubleValue, height.doubleValue));
	}];
}

+ (RACSignal *)rectsWithOrigin:(RACSignal *)originSignal size:(RACSignal *)sizeSignal {
	NSParameterAssert(originSignal != nil);
	NSParameterAssert(sizeSignal != nil);

	return [RACSignal combineLatest:@[ originSignal, sizeSignal ] reduce:^(NSValue *origin, NSValue *size) {
		NSAssert([origin isKindOfClass:NSValue.class] && origin.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", originSignal, origin);
		NSAssert([size isKindOfClass:NSValue.class] && size.med_geometryStructType == MEDGeometryStructTypeSize, @"Value sent by %@ is not a CGSize: %@", sizeSignal, size);

		CGPoint p = origin.med_pointValue;
		CGSize s = size.med_sizeValue;

		return MEDBox(CGRectMake(p.x, p.y, s.width, s.height));
	}];
}

+ (RACSignal *)rectsWithCenter:(RACSignal *)centerSignal size:(RACSignal *)sizeSignal {
	NSParameterAssert(centerSignal != nil);
	NSParameterAssert(sizeSignal != nil);

	return [RACSignal combineLatest:@[ centerSignal, sizeSignal ] reduce:^(NSValue *center, NSValue *size) {
		NSAssert([center isKindOfClass:NSValue.class] && center.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", centerSignal, center);
		NSAssert([size isKindOfClass:NSValue.class] && size.med_geometryStructType == MEDGeometryStructTypeSize, @"Value sent by %@ is not a CGSize: %@", sizeSignal, size);

		CGPoint p = center.med_pointValue;
		CGSize s = size.med_sizeValue;

		return MEDBox(CGRectMake(p.x - s.width / 2, p.y - s.height / 2, s.width, s.height));
	}];
}

+ (RACSignal *)rectsWithSize:(RACSignal *)sizeSignal {
	// CGPointZero apparently isn't typed (for MEDBox), so manually create it.
	RACSignal *originSignal = [RACSignal return:MEDBox(CGPointMake(0, 0))];
	return [self rectsWithOrigin:originSignal size:sizeSignal];
}

- (RACSignal *)size {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return MEDBox(value.med_rectValue.size);
	}];
}

- (RACSignal *)replaceSize:(RACSignal *)sizeSignal {
	return [self.class rectsWithOrigin:self.origin size:sizeSignal];
}

+ (RACSignal *)sizesWithWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	return [RACSignal combineLatest:@[ widthSignal, heightSignal ] reduce:^(NSNumber *width, NSNumber *height) {
		NSAssert([width isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", widthSignal, width);
		NSAssert([height isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", heightSignal, height);

		return MEDBox(CGSizeMake(width.doubleValue, height.doubleValue));
	}];
}

- (RACSignal *)width {
	return [self map:^(NSValue *value) {
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			return @(CGRectGetWidth(value.med_rectValue));
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);
			return @(value.med_sizeValue.width);
		}
	}];
}

- (RACSignal *)replaceWidth:(RACSignal *)widthSignal {
	NSParameterAssert(widthSignal != nil);

	return [RACSignal combineLatest:@[ widthSignal, self ] reduce:^(NSNumber *width, NSValue *value) {
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			CGRect rect = value.med_rectValue;
			rect.size.width = width.doubleValue;
			return MEDBox(rect);
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);

			CGSize size = value.med_sizeValue;
			size.width = width.doubleValue;
			return MEDBox(size);
		}
	}];
}

- (RACSignal *)height {
	return [self map:^(NSValue *value) {
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			return @(CGRectGetHeight(value.med_rectValue));
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);
			return @(value.med_sizeValue.height);
		}
	}];
}

- (RACSignal *)replaceHeight:(RACSignal *)heightSignal {
	NSParameterAssert(heightSignal != nil);

	return [RACSignal combineLatest:@[ heightSignal, self ] reduce:^(NSNumber *height, NSValue *value) {
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			CGRect rect = value.med_rectValue;
			rect.size.height = height.doubleValue;
			return MEDBox(rect);
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);

			CGSize size = value.med_sizeValue;
			size.height = height.doubleValue;
			return MEDBox(size);
		}
	}];
}

- (RACSignal *)origin {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return MEDBox(value.med_rectValue.origin);
	}];
}

- (RACSignal *)replaceOrigin:(RACSignal *)originSignal {
	return [self.class rectsWithOrigin:originSignal size:self.size];
}

- (RACSignal *)center {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return MEDBox(CGRectCenterPoint(value.med_rectValue));
	}];
}

+ (RACSignal *)pointsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);

	return [RACSignal combineLatest:@[ xSignal, ySignal ] reduce:^(NSNumber *x, NSNumber *y) {
		NSAssert([x isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", xSignal, x);
		NSAssert([y isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", ySignal, y);

		return MEDBox(CGPointMake(x.doubleValue, y.doubleValue));
	}];
}

- (RACSignal *)x {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", self, value);

		return @(value.med_pointValue.x);
	}];
} 

- (RACSignal *)replaceX:(RACSignal *)xSignal {
	return [self.class pointsWithX:xSignal Y:self.y];
}

- (RACSignal *)y {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", self, value);

		return @(value.med_pointValue.y);
	}];
}

- (RACSignal *)replaceY:(RACSignal *)ySignal {
	return [self.class pointsWithX:self.x Y:ySignal];
}

- (RACSignal *)minX {
	return [self positionOfEdge:[RACSignal return:@(CGRectMinXEdge)]];
}

- (RACSignal *)minY {
	return [self positionOfEdge:[RACSignal return:@(CGRectMinYEdge)]];
}

- (RACSignal *)centerX {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return @(CGRectGetMidX(value.med_rectValue));
	}];
}

- (RACSignal *)centerY {
	return [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return @(CGRectGetMidY(value.med_rectValue));
	}];
}

- (RACSignal *)maxX {
	return [self positionOfEdge:[RACSignal return:@(CGRectMaxXEdge)]];
}

- (RACSignal *)maxY {
	return [self positionOfEdge:[RACSignal return:@(CGRectMaxYEdge)]];
}

- (RACSignal *)positionOfEdge:(RACSignal *)edgeSignal {
	NSParameterAssert(edgeSignal != nil);

	RACReplaySubject *edgeSubject = [RACReplaySubject replaySubjectWithCapacity:1];
	[[edgeSignal multicast:edgeSubject] connect];

	// Terminates edgeSubject when the receiver completes.
	RACSignal *selfTerminatingEdge = [self doCompleted:^{
		[edgeSubject sendCompleted];
	}];

	return [RACSignal combineLatest:@[ edgeSubject, selfTerminatingEdge ] reduce:^ id (NSNumber *edge, NSValue *value) {
		NSAssert([edge isKindOfClass:NSNumber.class], @"Value sent by %@ is not a CGRectEdge number: %@", edgeSignal, edge);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGRect rect = value.med_rectValue;

		switch (edge.unsignedIntegerValue) {
			case CGRectMinXEdge:
				return @(CGRectGetMinX(rect));

			case CGRectMinYEdge:
				return @(CGRectGetMinY(rect));

			case CGRectMaxXEdge:
				return @(CGRectGetMaxX(rect));

			case CGRectMaxYEdge:
				return @(CGRectGetMaxY(rect));

			default:
				NSAssert(NO, @"Unrecognized edge: %@", edge);
				return nil;
		}
	}];
}

- (RACSignal *)leading {
	return [self positionOfEdge:RACSignal.leadingEdgeSignal];
}

- (RACSignal *)trailing {
	return [self positionOfEdge:RACSignal.trailingEdgeSignal];
}

- (RACSignal *)alignEdge:(RACSignal *)edgeSignal toPosition:(RACSignal *)positionSignal {
	NSParameterAssert(edgeSignal != nil);
	NSParameterAssert(positionSignal != nil);

	RACReplaySubject *edgeSubject = [RACReplaySubject replaySubjectWithCapacity:1];
	[[edgeSignal multicast:edgeSubject] connect];

	// Terminates edgeSubject when the receiver completes.
	RACSignal *selfTerminatingEdge = [self doCompleted:^{
		[edgeSubject sendCompleted];
	}];

	return [RACSignal combineLatest:@[ edgeSubject, positionSignal, selfTerminatingEdge ] reduce:^ id (NSNumber *edge, NSNumber *position, NSValue *value) {
		NSAssert([edge isKindOfClass:NSNumber.class], @"Value sent by %@ is not a CGRectEdge number: %@", edgeSignal, edge);
		NSAssert([position isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", positionSignal, position);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGRect rect = value.med_rectValue;

		switch (edge.unsignedIntegerValue) {
			case CGRectMinXEdge:
				rect.origin.x = position.doubleValue;
				break;

			case CGRectMinYEdge:
				rect.origin.y = position.doubleValue;
				break;

			case CGRectMaxXEdge:
				rect.origin.x = position.doubleValue - CGRectGetWidth(rect);
				break;

			case CGRectMaxYEdge:
				rect.origin.y = position.doubleValue - CGRectGetHeight(rect);
				break;

			default:
				NSAssert(NO, @"Unrecognized edge: %@", edge);
				return nil;
		}

		return MEDBox(rect);
	}];
}

- (RACSignal *)alignCenter:(RACSignal *)centerSignal {
	NSParameterAssert(centerSignal != nil);

	return [RACSignal combineLatest:@[ centerSignal, self ] reduce:^(NSValue *center, NSValue *value) {
		NSAssert([center isKindOfClass:NSValue.class] && center.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", centerSignal, center);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGFloat x = center.med_pointValue.x;
		CGFloat y = center.med_pointValue.y;

		CGRect rect = value.med_rectValue;
		return MEDBox(CGRectMake(x - CGRectGetWidth(rect) / 2, y - CGRectGetHeight(rect) / 2, CGRectGetWidth(rect), CGRectGetHeight(rect)));
	}];
}

- (RACSignal *)alignCenterX:(RACSignal *)centerXSignal {
	NSParameterAssert(centerXSignal != nil);

	return [RACSignal combineLatest:@[ centerXSignal, self ] reduce:^(NSNumber *position, NSValue *value) {
		NSAssert([position isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", centerXSignal, position);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGRect rect = value.med_rectValue;
		return MEDBox(CGRectMake(position.doubleValue - CGRectGetWidth(rect) / 2, CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect)));
	}];
}

- (RACSignal *)alignCenterY:(RACSignal *)centerYSignal {
	NSParameterAssert(centerYSignal != nil);

	return [RACSignal combineLatest:@[ centerYSignal, self ] reduce:^(NSNumber *position, NSValue *value) {
		NSAssert([position isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", centerYSignal, position);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGRect rect = value.med_rectValue;
		return MEDBox(CGRectMake(CGRectGetMinX(rect), position.doubleValue - CGRectGetHeight(rect) / 2, CGRectGetWidth(rect), CGRectGetHeight(rect)));
	}];
}

- (RACSignal *)alignBaseline:(RACSignal *)baselineSignal toBaseline:(RACSignal *)referenceBaselineSignal ofRect:(RACSignal *)referenceRectSignal {
	NSParameterAssert(baselineSignal != nil);
	NSParameterAssert(referenceBaselineSignal != nil);
	NSParameterAssert(referenceRectSignal != nil);

	return [RACSignal
		combineLatest:@[ referenceBaselineSignal, referenceRectSignal, baselineSignal, self ]
		reduce:^(NSNumber *referenceBaselineNum, NSValue *referenceRectValue, NSNumber *baselineNum, NSValue *rectValue) {
			NSAssert([referenceBaselineNum isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", referenceBaselineSignal, referenceBaselineNum);
			NSAssert([referenceRectValue isKindOfClass:NSValue.class] && referenceRectValue.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", referenceRectSignal, referenceRectValue);
			NSAssert([baselineNum isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", baselineSignal, baselineNum);
			NSAssert([rectValue isKindOfClass:NSValue.class] && rectValue.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, rectValue);

			CGRect rect = rectValue.med_rectValue;
			CGFloat baseline = baselineNum.doubleValue;

			CGRect referenceRect = referenceRectValue.med_rectValue;
			CGFloat referenceBaseline = referenceBaselineNum.doubleValue;

			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				// Flip the baselines so they're relative to a shared minY.
				baseline = CGRectGetHeight(rect) - baseline + CGRectGetMinY(rect);
				referenceBaseline = CGRectGetHeight(referenceRect) - referenceBaseline + CGRectGetMinY(referenceRect);

				rect = CGRectOffset(rect, 0, referenceBaseline - baseline);
			#elif TARGET_OS_MAC
				// Recalculate the baselines relative to a shared minY.
				baseline += CGRectGetMinY(rect);
				referenceBaseline += CGRectGetMinY(referenceRect);

				rect = CGRectOffset(rect, 0, referenceBaseline - baseline);
			#endif

			return MEDBox(rect);
		}];
}

- (RACSignal *)insetWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	// Subscribe to self last so that we don't skip any values sent
	// immediately. See https://github.com/github/ReactiveCocoa/issues/192.
	return [RACSignal combineLatest:@[ widthSignal, heightSignal, self ] reduce:^(NSNumber *width, NSNumber *height, NSValue *rect) {
		NSAssert([width isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", widthSignal, width);
		NSAssert([height isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", heightSignal, height);
		NSAssert([rect isKindOfClass:NSValue.class] && rect.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, rect);

		return MEDBox(CGRectInset(rect.med_rectValue, width.doubleValue, height.doubleValue));
	}];
}

- (RACSignal *)offsetX:(RACSignal *)xSignal Y:(RACSignal *)ySignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);

	return [RACSignal combineLatest:@[ xSignal, ySignal, self ] reduce:^(NSNumber *x, NSNumber *y, NSValue *value) {
		NSAssert([x isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", xSignal, x);
		NSAssert([y isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", ySignal, y);
	
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			return MEDBox(CGRectOffset(value.med_rectValue, x.doubleValue, y.doubleValue));
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypePoint, @"Unexpected type of value: %@", value);

			CGPoint offset = CGPointMake(x.doubleValue, y.doubleValue);
			return MEDBox(CGPointAdd(value.med_pointValue, offset));
		}
	}];
}

- (RACSignal *)sliceWithAmount:(RACSignal *)amountSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		NSAssert([amount isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", amountSignal, amount);
		NSAssert([rect isKindOfClass:NSValue.class] && rect.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, rect);

		return MEDBox(CGRectSlice(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (RACSignal *)remainderAfterSlicingAmount:(RACSignal *)amountSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		NSAssert([amount isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", amountSignal, amount);
		NSAssert([rect isKindOfClass:NSValue.class] && rect.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, rect);

		return MEDBox(CGRectRemainder(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (RACSignal *)growEdge:(CGRectEdge)edge byAmount:(RACSignal *)amountSignal {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		NSAssert([amount isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", amountSignal, amount);
		NSAssert([rect isKindOfClass:NSValue.class] && rect.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, rect);

		return MEDBox(CGRectGrow(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal fromEdge:(CGRectEdge)edge {
	return [self divideWithAmount:sliceAmountSignal padding:[RACSignal return:@0] fromEdge:edge];
}

- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal padding:(RACSignal *)paddingSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(sliceAmountSignal != nil);
	NSParameterAssert(paddingSignal != nil);

	RACSignal *amountPlusPadding = [RACSignal combineLatest:@[ sliceAmountSignal, paddingSignal ] reduce:^(NSNumber *amount, NSNumber *padding) {
		NSAssert([amount isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", sliceAmountSignal, amount);
		NSAssert([padding isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", paddingSignal, padding);

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

+ (RACSignal *)add:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a + b;
	});
}

+ (RACSignal *)subtract:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a - b;
	});
}

+ (RACSignal *)multiply:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a * b;
	});
}

+ (RACSignal *)divide:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a / b;
	});
}

- (RACSignal *)plus:(RACSignal *)addendSignal {
	NSParameterAssert(addendSignal != nil);

	return [RACSignal add:@[ self, addendSignal ]];
}

- (RACSignal *)minus:(RACSignal *)subtrahendSignal {
	NSParameterAssert(subtrahendSignal != nil);

	return [RACSignal subtract:@[ self, subtrahendSignal ]];
}

- (RACSignal *)multipliedBy:(RACSignal *)factorSignal {
	NSParameterAssert(factorSignal != nil);

	return [RACSignal multiply:@[ self, factorSignal ]];
}

- (RACSignal *)dividedBy:(RACSignal *)denominatorSignal {
	NSParameterAssert(denominatorSignal != nil);

	return [RACSignal divide:@[ self, denominatorSignal ]];
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
