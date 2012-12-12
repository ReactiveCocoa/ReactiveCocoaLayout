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
- (id<RACSignal>)rcl_size;

// Maps sizes to their `width` fields.
- (id<RACSignal>)rcl_width;

// Maps sizes to their `height` fields.
- (id<RACSignal>)rcl_height;

// Maps rectangles to their `origin` fields.
- (id<RACSignal>)rcl_origin;

// Maps points to their `x` fields.
- (id<RACSignal>)rcl_x;

// Maps points to their `y` fields.
- (id<RACSignal>)rcl_y;

// Insets a stream by rectangles by the given width and height.
- (id<RACSignal>)rcl_insetWidth:(CGFloat)width height:(CGFloat)height;

@end
