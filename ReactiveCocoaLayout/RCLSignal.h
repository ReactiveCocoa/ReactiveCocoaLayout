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
- (id<RCLSignal>)size;

// Maps sizes to their `width` fields.
- (id<RCLSignal>)width;

// Maps sizes to their `height` fields.
- (id<RCLSignal>)height;

// Maps rectangles to their `origin` fields.
- (id<RCLSignal>)origin;

// Maps points to their `x` fields.
- (id<RCLSignal>)x;

// Maps points to their `y` fields.
- (id<RCLSignal>)y;

// Insets a stream by rectangles by the given width and height.
- (id<RCLSignal>)insetWidth:(CGFloat)width height:(CGFloat)height;

- (id<RCLSignal>)sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;
- (id<RCLSignal>)remainderWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;

- (RACTuple *)divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;
- (RACTuple *)divideWithAmount:(CGFloat)amount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge;

@end
