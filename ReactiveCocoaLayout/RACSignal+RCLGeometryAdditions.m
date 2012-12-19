//
//  RACSignal+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RACSignal+RCLGeometryAdditions.h"
#import "RACSignal+RCLWritingDirectionAdditions.h"

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

- (RACSignal *)minX {
	return [self positionOfEdge:[RACSignal return:@(CGRectMinXEdge)]];
}

- (RACSignal *)minY {
	return [self positionOfEdge:[RACSignal return:@(CGRectMinYEdge)]];
}

- (RACSignal *)centerX {
	return [self map:^(NSValue *value) {
		return @(CGRectGetMidX(value.med_rectValue));
	}];
}

- (RACSignal *)centerY {
	return [self map:^(NSValue *value) {
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

@end
