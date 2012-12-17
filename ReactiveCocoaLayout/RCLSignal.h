//
//  RCLSignal.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "EXTConcreteProtocol.h"

// A concrete protocol representing a geometric signal.
//
// When conforming to this protocol in a custom class, only `@required` methods
// need to be implemented. Default implementations will automatically be
// provided for any methods marked as `@concrete`. For more information, see
// EXTConcreteProtocol.h.
@protocol RCLSignal <RACSignal>
@concrete

// Maps CGRect values to their `size` fields.
//
// Returns a signal of CGSize values.
- (id<RCLSignal>)size;

// Maps CGSize values to their `width` fields.
//
// Returns a signal of CGFloat values.
- (id<RCLSignal>)width;

// Maps CGSize values to their `height` fields.
//
// Returns a signal of CGFloat values.
- (id<RCLSignal>)height;

// Maps CGRect values to their `origin` fields.
//
// Returns a signal of CGPoint values.
- (id<RCLSignal>)origin;

// Maps CGPoint values to their `x` fields.
//
// Returns a signal of CGFloat values.
- (id<RCLSignal>)x;

// Maps CGPoint values to their `y` fields.
//
// Returns a signal of CGFloat values.
- (id<RCLSignal>)y;

// Insets each CGRect by the number of points sent from the given width and
// height signals.
//
// widthSignal  - A signal of CGFloat values, representing the number of points
//                to remove from both the left and right sides of the rectangle.
// heightSignal - A signal of CGFloat values, representing the number of points
//                to remove from both the top and bottom sides of the rectangle.
//
// Returns a signal of new, inset CGRect values.
- (id<RCLSignal>)insetWidth:(id<RACSignal>)widthSignal height:(id<RACSignal>)heightSignal;

// Trims each CGRect to only `amount` points in size, as measured starting from
// the given edge.
//
// amount - The number of points to include in the slice. If greater than the
//          size of a given rectangle, the result will be the entire rectangle.
// edge   - The edge from which to start including points in the slice.
//
// Returns a signal of CGRect slices.
- (id<RCLSignal>)sliceWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;

// Trims `amount` points from the given edge of each CGRect.
//
// amount - The number of points to remove. If greater than the size of a given
//          rectangle, the result will be CGRectZero.
// edge   - The edge from which to trim.
//
// Returns a signal of CGRect remainders.
- (id<RCLSignal>)remainderAfterSlicingAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;

// Invokes -divideWithAmount:padding:fromEdge: with a `padding` value of 0.
- (RACTuple *)divideWithAmount:(CGFloat)amount fromEdge:(CGRectEdge)edge;

// Divides each CGRect into two component rectangles, skipping the given amount
// of padding between them.
//
// sliceAmount - The number of points to include in the slice rectangle,
//               starting from `edge`. If greater than the size of a given
//               rectangle, the slice will be the entire rectangle, and the
//               remainder will be CGRectZero.
// padding     - The number of points of padding to omit between the slice and
//               remainder rectangles. If `padding + sliceAmount` is greater
//               than or equal to the size of a given rectangle, the remainder
//               will be CGRectZero.
// edge        - The edge from which division begins, proceeding toward the
//               opposite edge.
//
// Returns a RACTuple containing two signals, which will send the slices and
// remainders, respectively.
- (RACTuple *)divideWithAmount:(CGFloat)sliceAmount padding:(CGFloat)padding fromEdge:(CGRectEdge)edge;

@end
