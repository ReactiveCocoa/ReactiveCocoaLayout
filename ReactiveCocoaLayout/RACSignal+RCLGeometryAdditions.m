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
	} name:@"[%@] -animateWithDuration: %f curve: %li", self.name, (double)duration, (long)curve];
}

// When any signal sends an NSNumber, if -compare: invoked against the previous
// value (and passed the new value) returns `result`, the new value is sent on
// the returned signal.
static RACSignal *latestNumberMatchingComparisonResult(NSArray *signals, NSComparisonResult result, NSString *nameFormat, ...) NS_FORMAT_FUNCTION(3, 4) {
	NSCParameterAssert(signals != nil);

	RACSignal *signal = [[[RACSignal merge:signals]
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

	if (nameFormat != nil) {
		va_list args;
		va_start(args, nameFormat);
		signal.name = [[NSString alloc] initWithFormat:nameFormat arguments:args];
		va_end(args);
	}

	return signal;
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
static RACSignal *combineSignalsWithOperator(NSArray *signals, RCLBinaryOperator operator, NSString *nameFormat, ...) NS_FORMAT_FUNCTION(3, 4) {
	NSCParameterAssert(signals != nil);
	NSCParameterAssert(signals.count > 0);
	NSCParameterAssert(operator != nil);

	RACSignal *signal = [[[RACSignal combineLatest:signals]
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
	
	if (nameFormat != nil) {
		va_list args;
		va_start(args, nameFormat);
		signal.name = [[NSString alloc] initWithFormat:nameFormat arguments:args];
		va_end(args);
	}

	return signal;
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
// nameFormat  - A format string for the name of the resulting signal. This may
//				 be nil to not set a name.
// ...         - The arguments to be filled into `nameFormat`.
//
// Returns a signal of reduced values.
static RACSignal *combineAttributeWithRects(NSLayoutAttribute attribute, NSArray *signals, id reduceBlock, NSString *nameFormat, ...) NS_FORMAT_FUNCTION(4, 5) {
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
	RACSignal *signal = [RACSignal combineLatest:mutableSignals reduce:reduceBlock];

	if (nameFormat != nil) {
		va_list args;
		va_start(args, nameFormat);
		signal.name = [[NSString alloc] initWithFormat:nameFormat arguments:args];
		va_end(args);
	}

	return signal;
}

@implementation RACSignal (RCLGeometryAdditions)

+ (RACSignal *)rectsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal width:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ xSignal, ySignal, widthSignal, heightSignal ] reduce:^(NSNumber *x, NSNumber *y, NSNumber *width, NSNumber *height) {
		NSAssert([x isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", xSignal, x);
		NSAssert([y isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", ySignal, y);
		NSAssert([width isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", widthSignal, width);
		NSAssert([height isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", heightSignal, height);

		return MEDBox(CGRectMake(x.doubleValue, y.doubleValue, width.doubleValue, height.doubleValue));
	}];

	signal.name = [NSString stringWithFormat:@"+rectsWithX: %@ Y: %@ width: %@ height: %@", xSignal, ySignal, widthSignal, heightSignal];
	return signal;
}

+ (RACSignal *)rectsWithOrigin:(RACSignal *)originSignal size:(RACSignal *)sizeSignal {
	NSParameterAssert(originSignal != nil);
	NSParameterAssert(sizeSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ originSignal, sizeSignal ] reduce:^(NSValue *origin, NSValue *size) {
		NSAssert([origin isKindOfClass:NSValue.class] && origin.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", originSignal, origin);
		NSAssert([size isKindOfClass:NSValue.class] && size.med_geometryStructType == MEDGeometryStructTypeSize, @"Value sent by %@ is not a CGSize: %@", sizeSignal, size);

		CGPoint p = origin.med_pointValue;
		CGSize s = size.med_sizeValue;

		return MEDBox(CGRectMake(p.x, p.y, s.width, s.height));
	}];

	signal.name = [NSString stringWithFormat:@"+rectsWithOrigin: %@ size: %@", originSignal, sizeSignal];
	return signal;
}

+ (RACSignal *)rectsWithCenter:(RACSignal *)centerSignal size:(RACSignal *)sizeSignal {
	NSParameterAssert(centerSignal != nil);
	NSParameterAssert(sizeSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ centerSignal, sizeSignal ] reduce:^(NSValue *center, NSValue *size) {
		NSAssert([center isKindOfClass:NSValue.class] && center.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", centerSignal, center);
		NSAssert([size isKindOfClass:NSValue.class] && size.med_geometryStructType == MEDGeometryStructTypeSize, @"Value sent by %@ is not a CGSize: %@", sizeSignal, size);

		CGPoint p = center.med_pointValue;
		CGSize s = size.med_sizeValue;

		return MEDBox(CGRectMake(p.x - s.width / 2, p.y - s.height / 2, s.width, s.height));
	}];

	signal.name = [NSString stringWithFormat:@"+rectsWithCenter: %@ size: %@", centerSignal, sizeSignal];
	return signal;
}

+ (RACSignal *)rectsWithSize:(RACSignal *)sizeSignal {
	// CGPointZero apparently isn't typed (for MEDBox), so manually create it.
	RACSignal *originSignal = [RACSignal return:MEDBox(CGPointMake(0, 0))];

	RACSignal *signal = [self rectsWithOrigin:originSignal size:sizeSignal];
	signal.name = [NSString stringWithFormat:@"+rectsWithSize: %@", sizeSignal];
	return signal;
}

- (RACSignal *)size {
	RACSignal *signal = [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return MEDBox(value.med_rectValue.size);
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -size", self.name];
	return signal;
}

- (RACSignal *)replaceSize:(RACSignal *)sizeSignal {
	RACSignal *signal = [self.class rectsWithOrigin:self.origin size:sizeSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -replaceSize: %@", self.name, sizeSignal];
	return signal;
}

+ (RACSignal *)sizesWithWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ widthSignal, heightSignal ] reduce:^(NSNumber *width, NSNumber *height) {
		NSAssert([width isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", widthSignal, width);
		NSAssert([height isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", heightSignal, height);

		return MEDBox(CGSizeMake(width.doubleValue, height.doubleValue));
	}];

	signal.name = [NSString stringWithFormat:@"+sizesWithWidth: %@ height: %@", widthSignal, heightSignal];
	return signal;
}

- (RACSignal *)width {
	RACSignal *signal = [self map:^(NSValue *value) {
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			return @(CGRectGetWidth(value.med_rectValue));
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);
			return @(value.med_sizeValue.width);
		}
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -width", self.name];
	return signal;
}

- (RACSignal *)replaceWidth:(RACSignal *)widthSignal {
	NSParameterAssert(widthSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ widthSignal, self ] reduce:^(NSNumber *width, NSValue *value) {
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

	signal.name = [NSString stringWithFormat:@"[%@] -replaceWidth: %@", self.name, widthSignal];
	return signal;
}

- (RACSignal *)height {
	RACSignal *signal = [self map:^(NSValue *value) {
		if (value.med_geometryStructType == MEDGeometryStructTypeRect) {
			return @(CGRectGetHeight(value.med_rectValue));
		} else {
			NSAssert(value.med_geometryStructType == MEDGeometryStructTypeSize, @"Unexpected type of value: %@", value);
			return @(value.med_sizeValue.height);
		}
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -height", self.name];
	return signal;
}

- (RACSignal *)replaceHeight:(RACSignal *)heightSignal {
	NSParameterAssert(heightSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ heightSignal, self ] reduce:^(NSNumber *height, NSValue *value) {
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

	signal.name = [NSString stringWithFormat:@"[%@] -replaceHeight: %@", self.name, heightSignal];
	return signal;
}

- (RACSignal *)origin {
	RACSignal *signal = [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return MEDBox(value.med_rectValue.origin);
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -origin", self.name];
	return signal;
}

- (RACSignal *)replaceOrigin:(RACSignal *)originSignal {
	RACSignal *signal = [self.class rectsWithOrigin:originSignal size:self.size];
	signal.name = [NSString stringWithFormat:@"[%@] -replaceOrigin: %@", self.name, originSignal];
	return signal;
}

- (RACSignal *)center {
	RACSignal *signal = [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		return MEDBox(CGRectCenterPoint(value.med_rectValue));
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -center", self.name];
	return signal;
}

+ (RACSignal *)pointsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ xSignal, ySignal ] reduce:^(NSNumber *x, NSNumber *y) {
		NSAssert([x isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", xSignal, x);
		NSAssert([y isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", ySignal, y);

		return MEDBox(CGPointMake(x.doubleValue, y.doubleValue));
	}];

	signal.name = [NSString stringWithFormat:@"+pointsWithX: %@ Y: %@", xSignal, ySignal];
	return signal;
}

- (RACSignal *)x {
	RACSignal *signal = [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", self, value);

		return @(value.med_pointValue.x);
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -x", self.name];
	return signal;
} 

- (RACSignal *)replaceX:(RACSignal *)xSignal {
	RACSignal *signal = [self.class pointsWithX:xSignal Y:self.y];
	signal.name = [NSString stringWithFormat:@"[%@] -replaceX: %@", self.name, xSignal];
	return signal;
}

- (RACSignal *)y {
	RACSignal *signal = [self map:^(NSValue *value) {
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", self, value);

		return @(value.med_pointValue.y);
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -y", self.name];
	return signal;
}

- (RACSignal *)replaceY:(RACSignal *)ySignal {
	RACSignal *signal = [self.class pointsWithX:self.x Y:ySignal];
	signal.name = [NSString stringWithFormat:@"[%@] -replaceY: %@", self.name, ySignal];
	return signal;
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
	}, @"[%@] -valueForAttribute: %li", self.name, (long)attribute);
}

- (RACSignal *)left {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeLeft];
	signal.name = [NSString stringWithFormat:@"[%@] -left", self.name];
	return signal;
}

- (RACSignal *)right {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeRight];
	signal.name = [NSString stringWithFormat:@"[%@] -right", self.name];
	return signal;
}

- (RACSignal *)top {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeTop];
	signal.name = [NSString stringWithFormat:@"[%@] -top", self.name];
	return signal;
}

- (RACSignal *)bottom {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeBottom];
	signal.name = [NSString stringWithFormat:@"[%@] -bottom", self.name];
	return signal;
}

- (RACSignal *)leading {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeLeading];
	signal.name = [NSString stringWithFormat:@"[%@] -leading", self.name];
	return signal;
}

- (RACSignal *)trailing {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeTrailing];
	signal.name = [NSString stringWithFormat:@"[%@] -trailing", self.name];
	return signal;
}

- (RACSignal *)centerX {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeCenterX];
	signal.name = [NSString stringWithFormat:@"[%@] -centerX", self.name];
	return signal;
}

- (RACSignal *)centerY {
	RACSignal *signal = [self valueForAttribute:NSLayoutAttributeCenterY];
	signal.name = [NSString stringWithFormat:@"[%@] -centerY", self.name];
	return signal;
}

- (RACSignal *)alignAttribute:(NSLayoutAttribute)attribute to:(RACSignal *)valueSignal {
	NSParameterAssert(valueSignal != nil);

	return combineAttributeWithRects(attribute, @[ valueSignal, self ], ^ id (NSNumber *edge, NSNumber *num, NSValue *value) {
		NSAssert([num isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", valueSignal, num);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGFloat n = num.doubleValue;
		CGRect rect = value.med_rectValue;

		if (edge == nil) {
			switch (attribute) {
				case NSLayoutAttributeWidth:
					rect.size.width = n;
					break;

				case NSLayoutAttributeHeight:
					rect.size.height = n;
					break;

				case NSLayoutAttributeCenterX:
					rect.origin.x = n - CGRectGetWidth(rect) / 2;
					break;

				case NSLayoutAttributeCenterY:
					rect.origin.y = n - CGRectGetHeight(rect) / 2;
					break;

				default:
					NSAssert(NO, @"NSLayoutAttribute should have had a CGRectEdge: %li", (long)attribute);
					return nil;
			}
		} else {
			switch (edge.unsignedIntegerValue) {
				case CGRectMinXEdge:
					rect.origin.x = n;
					break;

				case CGRectMinYEdge:
					rect.origin.y = n;
					break;

				case CGRectMaxXEdge:
					rect.origin.x = n - CGRectGetWidth(rect);
					break;

				case CGRectMaxYEdge:
					rect.origin.y = n - CGRectGetHeight(rect);
					break;

				default:
					NSAssert(NO, @"Unrecognized CGRectEdge: %@", edge);
					return nil;
			}
		}

		return MEDBox(CGRectStandardize(rect));
	}, @"[%@] -alignAttribute: %li to: %@", self.name, (long)attribute, valueSignal);
}

- (RACSignal *)alignCenter:(RACSignal *)centerSignal {
	NSParameterAssert(centerSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ centerSignal, self ] reduce:^(NSValue *center, NSValue *value) {
		NSAssert([center isKindOfClass:NSValue.class] && center.med_geometryStructType == MEDGeometryStructTypePoint, @"Value sent by %@ is not a CGPoint: %@", centerSignal, center);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGFloat x = center.med_pointValue.x;
		CGFloat y = center.med_pointValue.y;

		CGRect rect = value.med_rectValue;
		return MEDBox(CGRectMake(x - CGRectGetWidth(rect) / 2, y - CGRectGetHeight(rect) / 2, CGRectGetWidth(rect), CGRectGetHeight(rect)));
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -alignCenter: %@", self.name, centerSignal];
	return signal;
}

- (RACSignal *)alignLeft:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeLeft to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignLeft: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignRight:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeRight to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignRight: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignTop:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeTop to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignTop: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignBottom:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeBottom to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignBottom: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignLeading:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeLeading to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignLeading: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignTrailing:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeTrailing to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignTrailing: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignWidth:(RACSignal *)amountSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeWidth to:amountSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignWidth: %@", self.name, amountSignal];
	return signal;
}

- (RACSignal *)alignHeight:(RACSignal *)amountSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeHeight to:amountSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignHeight: %@", self.name, amountSignal];
	return signal;
}

- (RACSignal *)alignCenterX:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeCenterX to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignCenterX: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignCenterY:(RACSignal *)positionSignal {
	RACSignal *signal = [self alignAttribute:NSLayoutAttributeCenterY to:positionSignal];
	signal.name = [NSString stringWithFormat:@"[%@] -alignCenterY: %@", self.name, positionSignal];
	return signal;
}

- (RACSignal *)alignBaseline:(RACSignal *)baselineSignal toBaseline:(RACSignal *)referenceBaselineSignal ofRect:(RACSignal *)referenceRectSignal {
	NSParameterAssert(baselineSignal != nil);
	NSParameterAssert(referenceBaselineSignal != nil);
	NSParameterAssert(referenceRectSignal != nil);

	RACSignal *signal = [RACSignal
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
	
	signal.name = [NSString stringWithFormat:@"[%@] -alignBaseline: %@ toBaseline: %@ ofRect: %@", self.name, baselineSignal, referenceBaselineSignal, referenceRectSignal];
	return signal;
}

- (RACSignal *)insetWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ widthSignal, heightSignal, self ] reduce:^(NSNumber *width, NSNumber *height, NSValue *rect) {
		NSAssert([width isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", widthSignal, width);
		NSAssert([height isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", heightSignal, height);
		NSAssert([rect isKindOfClass:NSValue.class] && rect.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, rect);

		return MEDBox(CGRectInset(rect.med_rectValue, width.doubleValue, height.doubleValue));
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -insetWidth: %@ height: %@", self.name, widthSignal, heightSignal];
	return signal;
}

- (RACSignal *)offsetX:(RACSignal *)xSignal Y:(RACSignal *)ySignal {
	NSParameterAssert(xSignal != nil);
	NSParameterAssert(ySignal != nil);

	RACSignal *signal = [RACSignal combineLatest:@[ xSignal, ySignal, self ] reduce:^(NSNumber *x, NSNumber *y, NSValue *value) {
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

	signal.name = [NSString stringWithFormat:@"[%@] -offsetX: %@ Y: %@", self.name, xSignal, ySignal];
	return signal;
}

- (RACSignal *)extendAttribute:(NSLayoutAttribute)attribute byAmount:(RACSignal *)amountSignal {
	NSParameterAssert(amountSignal != nil);

	return combineAttributeWithRects(attribute, @[ amountSignal, self ], ^ id (NSNumber *edge, NSNumber *amount, NSValue *value) {
		NSAssert([amount isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", amountSignal, amount);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGFloat n = amount.doubleValue;
		CGRect rect = value.med_rectValue;

		if (edge == nil) {
			switch (attribute) {
				case NSLayoutAttributeWidth:
					rect.size.width += n;
					rect.origin.x -= n / 2;
					break;

				case NSLayoutAttributeHeight:
					rect.size.height += n;
					rect.origin.y -= n / 2;
					break;

				case NSLayoutAttributeCenterX:
					rect.origin.x += n;
					break;

				case NSLayoutAttributeCenterY:
					rect.origin.y += n;
					break;

				default:
					NSAssert(NO, @"NSLayoutAttribute should have had a CGRectEdge: %li", (long)attribute);
					return nil;
			}
		} else {
			rect = CGRectGrow(rect, n, (CGRectEdge)edge.unsignedIntegerValue);
		}

		return MEDBox(CGRectStandardize(rect));
	}, @"[%@] -extendAttribute: %li byAmount: %@", self.name, (long)attribute, amountSignal);
}

- (RACSignal *)sliceWithAmount:(RACSignal *)amountSignal fromEdge:(NSLayoutAttribute)edgeAttribute {
	RACSignal *signal = [self divideWithAmount:amountSignal fromEdge:edgeAttribute][0];
	signal.name = [NSString stringWithFormat:@"[%@] -sliceWithAmount: %@ fromEdge: %li", self.name, amountSignal, (long)edgeAttribute];
	return signal;
}

- (RACSignal *)remainderAfterSlicingAmount:(RACSignal *)amountSignal fromEdge:(NSLayoutAttribute)edgeAttribute {
	RACSignal *signal = [self divideWithAmount:amountSignal fromEdge:edgeAttribute][1];
	signal.name = [NSString stringWithFormat:@"[%@] -remainderAfterSlicingAmount: %@ fromEdge: %li", self.name, amountSignal, (long)edgeAttribute];
	return signal;
}

- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal fromEdge:(NSLayoutAttribute)edgeAttribute {
	return [self divideWithAmount:sliceAmountSignal padding:[RACSignal return:@0] fromEdge:edgeAttribute];
}

- (RACTuple *)divideWithAmount:(RACSignal *)amountSignal padding:(RACSignal *)paddingSignal fromEdge:(NSLayoutAttribute)edgeAttribute {
	NSParameterAssert(amountSignal != nil);
	NSParameterAssert(paddingSignal != nil);

	RACSignal *combinedSignal = combineAttributeWithRects(edgeAttribute, @[ amountSignal, paddingSignal, self ], ^ id (NSNumber *edge, NSNumber *amount, NSNumber *padding, NSValue *value) {
		NSAssert(edge != nil, @"NSLayoutAttribute does not represent an edge: %li", (long)edgeAttribute);
		NSAssert([amount isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", amountSignal, amount);
		NSAssert([padding isKindOfClass:NSNumber.class], @"Value sent by %@ is not a number: %@", paddingSignal, padding);
		NSAssert([value isKindOfClass:NSValue.class] && value.med_geometryStructType == MEDGeometryStructTypeRect, @"Value sent by %@ is not a CGRect: %@", self, value);

		CGRect rect = value.med_rectValue;

		CGRect slice = CGRectZero;
		CGRect remainder = CGRectZero;
		CGRectDivideWithPadding(rect, &slice, &remainder, amount.doubleValue, padding.doubleValue, (CGRectEdge)edge.unsignedIntegerValue);

		return [RACTuple tupleWithObjects:MEDBox(slice), MEDBox(remainder), nil];
	}, nil);

	// Now, convert Signal[(Rect, Rect)] into (Signal[Rect], Signal[Rect]).
	RACSignal *sliceSignal = [combinedSignal map:^(RACTuple *tuple) {
		return tuple[0];
	}];

	RACSignal *remainderSignal = [combinedSignal map:^(RACTuple *tuple) {
		return tuple[1];
	}];

	NSString *invocationName = [NSString stringWithFormat:@"-divideWithAmount: %@ padding: %@ fromEdge: %li", amountSignal, paddingSignal, (long)edgeAttribute];

	sliceSignal.name = [NSString stringWithFormat:@"[%@] SLICE OF %@", self.name, invocationName];
	remainderSignal.name = [NSString stringWithFormat:@"[%@] REMAINDER OF %@", self.name, invocationName];
	return [RACTuple tupleWithObjects:sliceSignal, remainderSignal, nil];
}

+ (RACSignal *)max:(NSArray *)signals {
	return latestNumberMatchingComparisonResult(signals, NSOrderedAscending, @"+max: %@", signals);
}

+ (RACSignal *)min:(NSArray *)signals {
	return latestNumberMatchingComparisonResult(signals, NSOrderedDescending, @"+min: %@", signals);
}

+ (RACSignal *)add:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a + b;
	}, @"+add: %@", signals);
}

+ (RACSignal *)subtract:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a - b;
	}, @"+subtract: %@", signals);
}

+ (RACSignal *)multiply:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a * b;
	}, @"+multiply: %@", signals);
}

+ (RACSignal *)divide:(NSArray *)signals {
	return combineSignalsWithOperator(signals, ^(CGFloat a, CGFloat b) {
		return a / b;
	}, @"+divide: %@", signals);
}

- (RACSignal *)plus:(RACSignal *)addendSignal {
	NSParameterAssert(addendSignal != nil);

	return combineSignalsWithOperator(@[ self, addendSignal ], ^(CGFloat a, CGFloat b) {
		return a + b;
	}, @"[%@] -plus: %@", self, addendSignal);
}

- (RACSignal *)minus:(RACSignal *)subtrahendSignal {
	NSParameterAssert(subtrahendSignal != nil);

	return combineSignalsWithOperator(@[ self, subtrahendSignal ], ^(CGFloat a, CGFloat b) {
		return a - b;
	}, @"[%@] -minus: %@", self, subtrahendSignal);
}

- (RACSignal *)multipliedBy:(RACSignal *)factorSignal {
	NSParameterAssert(factorSignal != nil);

	return combineSignalsWithOperator(@[ self, factorSignal ], ^(CGFloat a, CGFloat b) {
		return a * b;
	}, @"[%@] -multipliedBy: %@", self, factorSignal);
}

- (RACSignal *)dividedBy:(RACSignal *)denominatorSignal {
	NSParameterAssert(denominatorSignal != nil);

	return combineSignalsWithOperator(@[ self, denominatorSignal ], ^(CGFloat a, CGFloat b) {
		return a / b;
	}, @"[%@] -dividedBy: %@", self, denominatorSignal);
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

- (RACSignal *)floor {
	RACSignal *signal = [self map:^ id (id value) {
		if ([value isKindOfClass:NSNumber.class]) {
			return @(floor([value doubleValue]));
		}

		NSAssert([value isKindOfClass:NSValue.class], @"Expected a number or value, got %@", value);

		switch ([value med_geometryStructType]) {
			case MEDGeometryStructTypeRect:
				return MEDBox(CGRectFloor([value med_rectValue]));

			case MEDGeometryStructTypePoint:
				return MEDBox(CGPointFloor([value med_pointValue]));

			case MEDGeometryStructTypeSize: {
				CGSize size = [value med_sizeValue];
				size.width = floor(size.width);
				size.height = floor(size.height);
				return MEDBox(size);
			}

			default:
				NSAssert(NO, @"Unsupported type of value to floor: %@", value);
				return nil;
		}
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -floor", self.name];
	return signal;
}

- (RACSignal *)ceil {
	RACSignal *signal = [self map:^ id (id value) {
		if ([value isKindOfClass:NSNumber.class]) {
			return @(ceil([value doubleValue]));
		}

		NSAssert([value isKindOfClass:NSValue.class], @"Expected a number or value, got %@", value);

		switch ([value med_geometryStructType]) {
			case MEDGeometryStructTypeRect:
				return MEDBox(CGRectIntegral([value med_rectValue]));

			case MEDGeometryStructTypePoint: {
				CGPoint point = [value med_pointValue];
				point.x = floor(point.x);
				point.y = floor(point.y);
				return MEDBox(point);
			}

			case MEDGeometryStructTypeSize: {
				CGSize size = [value med_sizeValue];
				size.width = ceil(size.width);
				size.height = ceil(size.height);
				return MEDBox(size);
			}

			default:
				NSAssert(NO, @"Unsupported type of value to ceil: %@", value);
				return nil;
		}
	}];

	signal.name = [NSString stringWithFormat:@"[%@] -ceil", self.name];
	return signal;
}

@end
