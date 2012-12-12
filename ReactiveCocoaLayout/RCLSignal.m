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

- (id<RCLSignal>)rcl_size {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithSize:value.rectValue.size];
	}];
}

- (id<RCLSignal>)rcl_origin {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithPoint:value.rectValue.origin];
	}];
}

- (id<RCLSignal>)rcl_width {
	return [self map:^(NSValue *value) {
		return @(value.sizeValue.width);
	}];
}

- (id<RCLSignal>)rcl_height {
	return [self map:^(NSValue *value) {
		return @(value.sizeValue.height);
	}];
}

- (id<RCLSignal>)rcl_x {
	return [self map:^(NSValue *value) {
		return @(value.pointValue.x);
	}];
}

- (id<RCLSignal>)rcl_y {
	return [self map:^(NSValue *value) {
		return @(value.pointValue.y);
	}];
}

- (id<RCLSignal>)rcl_insetWidth:(CGFloat)width height:(CGFloat)height {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectInset(value.rectValue, width, height)];
	}];
}

- (id<RCLSignal>)rcl_sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectSlice(value.rectValue, amount, edge)];
	}];
}

- (id<RCLSignal>)rcl_remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectRemainder(value.rectValue, amount, edge)];
	}];
}

- (RACTuple *)rcl_divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self rcl_divideWithAmount:amount padding:0 fromEdge:edge];
}

- (RACTuple *)rcl_divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge {
	return [RACTuple tupleWithObjects:[self rcl_sliceWithAmount:amount fromEdge:edge], [self rcl_remainderWithAmount:fmax(0, amount + padding) fromEdge:edge], nil];
}

@end
