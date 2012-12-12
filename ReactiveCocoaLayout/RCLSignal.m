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
		return [NSValue valueWithSize:value.rectValue.size];
	}];
}

- (id<RCLSignal>)origin {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithPoint:value.rectValue.origin];
	}];
}

- (id<RCLSignal>)width {
	return [self map:^(NSValue *value) {
		return @(value.sizeValue.width);
	}];
}

- (id<RCLSignal>)height {
	return [self map:^(NSValue *value) {
		return @(value.sizeValue.height);
	}];
}

- (id<RCLSignal>)x {
	return [self map:^(NSValue *value) {
		return @(value.pointValue.x);
	}];
}

- (id<RCLSignal>)y {
	return [self map:^(NSValue *value) {
		return @(value.pointValue.y);
	}];
}

- (id<RCLSignal>)insetWidth:(CGFloat)width height:(CGFloat)height {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectInset(value.rectValue, width, height)];
	}];
}

- (id<RCLSignal>)sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectSlice(value.rectValue, amount, edge)];
	}];
}

- (id<RCLSignal>)remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectRemainder(value.rectValue, amount, edge)];
	}];
}

- (RACTuple *)divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self divideWithAmount:amount padding:0 fromEdge:edge];
}

- (RACTuple *)divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge {
	return [RACTuple tupleWithObjects:[self sliceWithAmount:amount fromEdge:edge], [self remainderWithAmount:fmax(0, amount + padding) fromEdge:edge], nil];
}

@end
