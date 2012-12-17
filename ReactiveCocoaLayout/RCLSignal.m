//
//  RCLSignal.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RCLSignal.h"

// When any signal sends an NSNumber, if -compare: invoked against the previous
// value (and passed the new value) returns `result`, the new value is sent on
// the returned signal.
static id<RCLSignal> latestNumberMatchingComparisonResult(NSArray *signals, NSComparisonResult result) {
	NSCParameterAssert(signals != nil);

	return (id)[[[RACSignal merge:signals]
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

- (id)insetWidth:(id<RACSignal>)widthSignal height:(id<RACSignal>)heightSignal {
	NSParameterAssert(widthSignal != nil);
	NSParameterAssert(heightSignal != nil);

	// Subscribe to self last so that we don't skip any values sent
	// immediately. See https://github.com/github/ReactiveCocoa/issues/192.
	return [RACSignal combineLatest:@[ widthSignal, heightSignal, self ] reduce:^(NSNumber *width, NSNumber *height, NSValue *rect) {
		return MEDBox(CGRectInset(rect.med_rectValue, width.doubleValue, height.doubleValue));
	}];
}

- (id)sliceWithAmount:(id<RACSignal>)amountSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		return MEDBox(CGRectSlice(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (id)remainderAfterSlicingAmount:(id<RACSignal>)amountSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(amountSignal != nil);

	return [RACSignal combineLatest:@[ amountSignal, self ] reduce:^(NSNumber *amount, NSValue *rect) {
		return MEDBox(CGRectRemainder(rect.med_rectValue, amount.doubleValue, edge));
	}];
}

- (RACTuple *)divideWithAmount:(id<RACSignal>)sliceAmountSignal fromEdge:(CGRectEdge)edge {
	return [self divideWithAmount:sliceAmountSignal padding:[RACSignal return:@0] fromEdge:edge];
}

- (RACTuple *)divideWithAmount:(id<RACSignal>)sliceAmountSignal padding:(id<RACSignal>)paddingSignal fromEdge:(CGRectEdge)edge {
	NSParameterAssert(sliceAmountSignal != nil);
	NSParameterAssert(paddingSignal != nil);

	id<RACSignal> amountPlusPadding = [RACSignal combineLatest:@[ sliceAmountSignal, paddingSignal ] reduce:^(NSNumber *amount, NSNumber *padding) {
		return @(amount.doubleValue + padding.doubleValue);
	}];

	id<RCLSignal> sliceSignal = [self sliceWithAmount:sliceAmountSignal fromEdge:edge];
	id<RCLSignal> remainderSignal = [self remainderAfterSlicingAmount:amountPlusPadding fromEdge:edge];

	return [RACTuple tupleWithObjects:sliceSignal, remainderSignal, nil];
}

+ (id<RCLSignal>)max:(NSArray *)signals {
	return latestNumberMatchingComparisonResult(signals, NSOrderedAscending);
}

+ (id<RCLSignal>)min:(NSArray *)signals {
	return latestNumberMatchingComparisonResult(signals, NSOrderedDescending);
}

@end
