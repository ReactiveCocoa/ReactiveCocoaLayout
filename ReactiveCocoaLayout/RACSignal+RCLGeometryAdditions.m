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

// Combines the values of the two signals using the given operator.
//
// The values may be CGFloats, CGSizes, or CGPoints, but both signals must send
// values of the same type.
//
// Returns a signal of results, using the same type as the input values.
static RACSignal *combineSignalsWithOperator(RACSignal *a, RACSignal *b, CGFloat (^operator)(CGFloat, CGFloat)) {
	NSCParameterAssert(a != nil);
	NSCParameterAssert(b != nil);
	NSCParameterAssert(operator != nil);

	return [RACSignal combineLatest:@[ a, b ] reduce:^ id (id valueA, id valueB) {
		if ([valueA isKindOfClass:NSNumber.class]) {
			NSCAssert([valueB isKindOfClass:NSNumber.class], @"%@ is a number, but %@ is not", valueA, valueB);

			return @(operator([valueA doubleValue], [valueB doubleValue]));
		}

		NSCAssert([valueA isKindOfClass:NSValue.class], @"%@ is not a number, so it should be an NSValue", valueA);
		NSCAssert([valueB isKindOfClass:NSValue.class], @"%@ is an NSValue, but %@ is not", valueA, valueB);
		NSCAssert([valueA med_geometryStructType] == [valueB med_geometryStructType], @"Values do not contain the same type of geometry structure: %@, %@", valueA, valueB);

		switch ([valueA med_geometryStructType]) {
			case MEDGeometryStructTypePoint: {
				CGPoint pointA = [valueA med_pointValue];
				CGPoint pointB = [valueB med_pointValue];

				CGPoint result = CGPointMake(operator(pointA.x, pointB.x), operator(pointA.y, pointB.y));
				return MEDBox(result);
			}

			case MEDGeometryStructTypeSize: {
				CGSize sizeA = [valueA med_sizeValue];
				CGSize sizeB = [valueB med_sizeValue];

				CGSize result = CGSizeMake(operator(sizeA.width, sizeB.width), operator(sizeA.height, sizeB.height));
				return MEDBox(result);
			}

			case MEDGeometryStructTypeRect:
			default:
				NSCAssert(NO, @"Values must contain CGSizes or CGPoints: %@, %@", valueA, valueB);
				return nil;
		}
	}];
}

// Combines the CGRectEdge corresponding to a layout attribute, and the values
// from the given signals.
//
// attribute   - The layout attribute to retrieve the edge for. If the layout
//				 attribute does not describe one of the edges of a rectangle, no
//				 `edge` will be provided to the `reduceBlock`. Must not be
//				 NSLayoutAttributeBaseline.
// signals	   - The signals to combine the values of. This must contain at
//				 least one signal.
// reduceBlock - A block which combines the NSNumber-boxed CGRectEdge (if
//				 `attribute` corresponds to one), or `nil` (if it does not) and
//				 the values of each signal in the `signals` array.
//
// Returns a signal of reduced values.
static RACSignal *combineAttributeWithRects(NSLayoutAttribute attribute, NSArray *signals, id reduceBlock) {
	NSCParameterAssert(attribute != NSLayoutAttributeBaseline);
	NSCParameterAssert(attribute != NSLayoutAttributeNotAnAttribute);
	NSCParameterAssert(signals.count > 0);

	RACSignal *edgeSignal = nil;
	NSMutableArray *mutableSignals = [signals mutableCopy];

	switch (attribute) {
		// TODO: Consider modified view coordinate systems?
		case NSLayoutAttributeLeft:
			edgeSignal = [RACSignal return:@(CGRectMinXEdge)];
			break;

		case NSLayoutAttributeRight:
			edgeSignal = [RACSignal return:@(CGRectMaxXEdge)];
			break;

	#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
		case NSLayoutAttributeTop:
			edgeSignal = [RACSignal return:@(CGRectMinYEdge)];
			break;

		case NSLayoutAttributeBottom:
			edgeSignal = [RACSignal return:@(CGRectMaxYEdge)];
			break;
	#elif TARGET_OS_MAC
		case NSLayoutAttributeTop:
			edgeSignal = [RACSignal return:@(CGRectMaxYEdge)];
			break;

		case NSLayoutAttributeBottom:
			edgeSignal = [RACSignal return:@(CGRectMinYEdge)];
			break;
	#endif

		case NSLayoutAttributeLeading:
		case NSLayoutAttributeTrailing: {
			RACReplaySubject *edgeSubject = [RACReplaySubject replaySubjectWithCapacity:1];

			RACSignal *baseSignal = (attribute == NSLayoutAttributeLeading ? RACSignal.leadingEdgeSignal : RACSignal.trailingEdgeSignal);
			edgeSignal = [[baseSignal multicast:edgeSubject] autoconnect];

			// Terminate edgeSubject when one of the given signals completes
			// (doesn't really matter which one).
			mutableSignals[0] = [mutableSignals[0] doCompleted:^{
				[edgeSubject sendCompleted];
			}];

			break;
		}

		case NSLayoutAttributeWidth:
		case NSLayoutAttributeHeight:
		case NSLayoutAttributeCenterX:
		case NSLayoutAttributeCenterY:
			// No sensical edge for these attributes.
			edgeSignal = [RACSignal return:nil];
			break;

		default:
			NSCAssert(NO, @"Unrecognized NSLayoutAttribute: %li", (long)attribute);
			return nil;
	}

	[mutableSignals insertObject:edgeSignal atIndex:0];
	return [RACSignal combineLatest:mutableSignals reduce:reduceBlock];
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

+ (RACSignal *)rectsWithCenter:(RACSignal *)centerSignal size:(RACSignal *)sizeSignal {
	NSParameterAssert(centerSignal != nil);
	NSParameterAssert(sizeSignal != nil);

	return [RACSignal combineLatest:@[ centerSignal, sizeSignal ] reduce:^(NSValue *center, NSValue *size) {
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
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			return @(CGRectGetWidth(value.med_rectValue));
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);
			return @(value.med_sizeValue.width);
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

- (RACSignal *)origin {
	return [self map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.origin);
	}];
}

- (RACSignal *)center {
	return [self map:^(NSValue *value) {
		return MEDBox(CGRectCenterPoint(value.med_rectValue));
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

- (RACSignal *)valueForAttribute:(NSLayoutAttribute)attribute {
	return combineAttributeWithRects(attribute, @[ self ], ^ id (NSNumber *edge, NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGRect rect = value.med_rectValue;
		if (edge == nil) {
			switch (attribute) {
				case NSLayoutAttributeWidth:
					return @(CGRectGetWidth(rect));

				case NSLayoutAttributeHeight:
					return @(CGRectGetHeight(rect));

				case NSLayoutAttributeCenterX:
					return @(CGRectGetMidX(rect));

				case NSLayoutAttributeCenterY:
					return @(CGRectGetMidY(rect));

				default:
					NSAssert(NO, @"NSLayoutAttribute should have had a CGRectEdge: %li", (long)attribute);
					return nil;
			}
		} else {
			switch (edge.unsignedIntegerValue) {
				case CGRectMinXEdge:
					return @(CGRectGetMinX(rect));

				case CGRectMaxXEdge:
					return @(CGRectGetMaxX(rect));

				case CGRectMinYEdge:
					return @(CGRectGetMinY(rect));

				case CGRectMaxYEdge:
					return @(CGRectGetMaxY(rect));

				default:
					NSAssert(NO, @"Unrecognized CGRectEdge: %@", edge);
					return nil;
			}
		}
	});
}

- (RACSignal *)left {
	return [self valueForAttribute:NSLayoutAttributeLeft];
}

- (RACSignal *)right {
	return [self valueForAttribute:NSLayoutAttributeRight];
}

- (RACSignal *)top {
	return [self valueForAttribute:NSLayoutAttributeTop];
}

- (RACSignal *)bottom {
	return [self valueForAttribute:NSLayoutAttributeBottom];
}

- (RACSignal *)leading {
	return [self valueForAttribute:NSLayoutAttributeLeading];
}

- (RACSignal *)trailing {
	return [self valueForAttribute:NSLayoutAttributeTrailing];
}

- (RACSignal *)centerX {
	return [self valueForAttribute:NSLayoutAttributeCenterX];
}

- (RACSignal *)centerY {
	return [self valueForAttribute:NSLayoutAttributeCenterY];
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
		CGFloat x = center.med_pointValue.x;
		CGFloat y = center.med_pointValue.y;

		CGRect rect = value.med_rectValue;
		return MEDBox(CGRectMake(x - CGRectGetWidth(rect) / 2, y - CGRectGetHeight(rect) / 2, CGRectGetWidth(rect), CGRectGetHeight(rect)));
	}];
}

- (RACSignal *)alignCenterX:(RACSignal *)centerXSignal {
	NSParameterAssert(centerXSignal != nil);

	return [RACSignal combineLatest:@[ centerXSignal, self ] reduce:^(NSNumber *position, NSValue *value) {
		CGRect rect = value.med_rectValue;
		return MEDBox(CGRectMake(position.doubleValue - CGRectGetWidth(rect) / 2, CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect)));
	}];
}

- (RACSignal *)alignCenterY:(RACSignal *)centerYSignal {
	NSParameterAssert(centerYSignal != nil);

	return [RACSignal combineLatest:@[ centerYSignal, self ] reduce:^(NSNumber *position, NSValue *value) {
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

- (RACSignal *)growEdge:(CGRectEdge)edge byAmount:(RACSignal *)amountSignal {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
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

- (RACSignal *)plus:(RACSignal *)addendSignal {
	return combineSignalsWithOperator(self, addendSignal, ^(CGFloat a, CGFloat b) {
		return a + b;
	});
}

- (RACSignal *)minus:(RACSignal *)subtrahendSignal {
	return combineSignalsWithOperator(self, subtrahendSignal, ^(CGFloat a, CGFloat b) {
		return a - b;
	});
}

- (RACSignal *)multipliedBy:(RACSignal *)factorSignal {
	return combineSignalsWithOperator(self, factorSignal, ^(CGFloat a, CGFloat b) {
		return a * b;
	});
}

- (RACSignal *)dividedBy:(RACSignal *)denominatorSignal {
	return combineSignalsWithOperator(self, denominatorSignal, ^(CGFloat a, CGFloat b) {
		return a / b;
	});
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
