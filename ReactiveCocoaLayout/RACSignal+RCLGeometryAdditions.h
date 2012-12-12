//
//  RACSignal+RCLGeometryAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "EXTProtocolCategory.h"

@pcategoryinterface(RACSignal, RCLGeometryAdditions)

// Maps rectangles to their `size` fields.
- (id)rcl_size;

// Maps sizes to their `width` fields.
- (id)rcl_width;

// Maps sizes to their `height` fields.
- (id)rcl_height;

// Maps rectangles to their `origin` fields.
- (id)rcl_origin;

// Maps points to their `x` fields.
- (id)rcl_x;

// Maps points to their `y` fields.
- (id)rcl_y;

// Insets a stream by rectangles by the given width and height.
- (id)rcl_insetWidth:(CGFloat)width height:(CGFloat)height;

- (id)rcl_sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;
- (id)rcl_remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;

- (RACTuple *)rcl_divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;
- (RACTuple *)rcl_divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge;

@end
