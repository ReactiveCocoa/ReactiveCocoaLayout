//
//  RACSignal+RCLGeometryAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RACSignal+RCLGeometryAdditions.h"

@pcategoryimplementation(RACSignal, RCLGeometryAdditions)

- (id<RACSignal>)rcl_size {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithSize:value.rectValue.size];
	}];
}

- (id<RACSignal>)rcl_origin {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithPoint:value.rectValue.origin];
	}];
}

- (id<RACSignal>)rcl_width {
	return [self map:^(NSValue *value) {
		return @(value.sizeValue.width);
	}];
}

- (id<RACSignal>)rcl_height {
	return [self map:^(NSValue *value) {
		return @(value.sizeValue.height);
	}];
}

- (id<RACSignal>)rcl_x {
	return [self map:^(NSValue *value) {
		return @(value.pointValue.x);
	}];
}

- (id<RACSignal>)rcl_y {
	return [self map:^(NSValue *value) {
		return @(value.pointValue.y);
	}];
}

- (id<RACSignal>)rcl_insetWidth:(CGFloat)width height:(CGFloat)height {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectInset(value.rectValue, width, height)];
	}];
}

- (id<RACSignal>)rcl_sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectSlice(value.rectValue, amount, edge)];
	}];
}

- (id<RACSignal>)rcl_remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge {
	return [self map:^(NSValue *value) {
		return [NSValue valueWithRect:CGRectRemainder(value.rectValue, amount, edge)];
	}];
}

@end
