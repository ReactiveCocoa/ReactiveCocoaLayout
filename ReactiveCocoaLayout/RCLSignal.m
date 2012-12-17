//
//  RCLSignal.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RCLSignal.h"

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

- (id<RCLSignal>)sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return MEDBox(CGRectSlice(value.med_rectValue, amount, edge));
	}];
}

- (id<RCLSignal>)remainderAfterSlicingAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return MEDBox(CGRectRemainder(value.med_rectValue, amount, edge));
	}];
}

- (RACTuple *)divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self divideWithAmount:amount padding:0 fromEdge:edge];
}

- (RACTuple *)divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge {
	return [RACTuple tupleWithObjects:[self sliceWithAmount:amount fromEdge:edge], [self remainderAfterSlicingAmount:fmax(0, amount + padding) fromEdge:edge], nil];
}

@end
