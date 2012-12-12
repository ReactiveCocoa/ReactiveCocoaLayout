//
//  RCLSignal.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "EXTConcreteProtocol.h"

@protocol RCLSignal <RACSignal>
@concrete

// Maps rectangles to their `size` fields.
- (id<RCLSignal>)rcl_size;

// Maps sizes to their `width` fields.
- (id<RCLSignal>)rcl_width;

// Maps sizes to their `height` fields.
- (id<RCLSignal>)rcl_height;

// Maps rectangles to their `origin` fields.
- (id<RCLSignal>)rcl_origin;

// Maps points to their `x` fields.
- (id<RCLSignal>)rcl_x;

// Maps points to their `y` fields.
- (id<RCLSignal>)rcl_y;

// Insets a stream by rectangles by the given width and height.
- (id<RCLSignal>)rcl_insetWidth:(CGFloat)width height:(CGFloat)height;

- (id<RCLSignal>)rcl_sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;
- (id<RCLSignal>)rcl_remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;

- (RACTuple *)rcl_divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;
- (RACTuple *)rcl_divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge;

@end
