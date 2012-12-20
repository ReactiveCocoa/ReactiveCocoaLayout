//
//  RACSignal+RCLGeometryAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

// Defines the curve (timing function) for an animation.
//
// RCLAnimationCurveDefault   - The default or inherited animation curve.
// RCLAnimationCurveEaseInOut - Begins the animation slowly, speeds up in the
//                              middle, and then slows to a stop.
// RCLAnimationCurveEaseIn    - Begins the animation slowly and speeds up to
//                              a stop.
// RCLAnimationCurveEaseOut   - Begins the animation quickly and slows down to
//                              a stop.
// RCLAnimationCurveLinear    - Animates with the same pace over the duration of
//                              the animation.
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    typedef enum : UIViewAnimationOptions {
        RCLAnimationCurveDefault = 0,
        RCLAnimationCurveEaseInOut = UIViewAnimationOptionCurveEaseInOut,
        RCLAnimationCurveEaseIn = UIViewAnimationOptionCurveEaseIn,
        RCLAnimationCurveEaseOut = UIViewAnimationOptionCurveEaseOut,
        RCLAnimationCurveLinear = UIViewAnimationOptionCurveLinear
    } RCLAnimationCurve;
#elif TARGET_OS_MAC
    typedef enum : NSUInteger {
        RCLAnimationCurveDefault,
        RCLAnimationCurveEaseInOut,
        RCLAnimationCurveEaseIn,
        RCLAnimationCurveEaseOut,
        RCLAnimationCurveLinear
    } RCLAnimationCurve;
#endif

// Adds geometry functions to RACSignal.
@interface RACSignal (RCLGeometryAdditions)

// Constructs rects from the given X, Y, width, and height signals.
//
// Returns a signal of CGRect values.
+ (RACSignal *)rectsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal width:(RACSignal *)widthSignal height:(RACSignal *)heightSignal;

// Constructs rects from the given origin and size signals.
//
// Returns a signal of CGRect values.
+ (RACSignal *)rectsWithOrigin:(RACSignal *)originSignal size:(RACSignal *)sizeSignal;

// Maps CGRect values to their `size` fields.
//
// Returns a signal of CGSize values.
- (RACSignal *)size;

// Constructs sizes from the given width and height signals.
//
// Returns a signal of CGSize values.
+ (RACSignal *)sizesWithWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal;

// Maps CGSize values to their `width` fields.
//
// Returns a signal of CGFloat values.
- (RACSignal *)width;

// Maps CGSize values to their `height` fields.
//
// Returns a signal of CGFloat values.
- (RACSignal *)height;

// Maps CGRect values to their `origin` fields.
//
// Returns a signal of CGPoint values.
- (RACSignal *)origin;

// Constructs points from the given X and Y signals.
//
// Returns a signal of CGPoint values.
+ (RACSignal *)pointsWithX:(RACSignal *)xSignal Y:(RACSignal *)ySignal;

// Maps CGPoint values to their `x` fields.
//
// Returns a signal of CGFloat values.
- (RACSignal *)x;

// Maps CGPoint values to their `y` fields.
//
// Returns a signal of CGFloat values.
- (RACSignal *)y;

// Insets each CGRect by the number of points sent from the given width and
// height signals.
//
// widthSignal  - A signal of CGFloat values, representing the number of points
//                to remove from both the left and right sides of the rectangle.
// heightSignal - A signal of CGFloat values, representing the number of points
//                to remove from both the top and bottom sides of the rectangle.
//
// Returns a signal of new, inset CGRect values.
- (RACSignal *)insetWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal;

// Trims each CGRect to the number of points sent from `amountSignal`, as
// measured starting from the given edge.
//
// amountSignal - A signal of CGFloat values, representing the number of points
//                to include in the slice. If greater than the size of a given
//                rectangle, the result will be the entire rectangle.
// edge         - The edge from which to start including points in the slice.
//
// Returns a signal of CGRect slices.
- (RACSignal *)sliceWithAmount:(RACSignal *)amountSignal fromEdge:(CGRectEdge)edge;

// From the given edge of each CGRect, trims the number of points sent from
// `amountSignal`.
//
// amountSignal - A signal of CGFloat values, representing the number of points
//                to remove. If greater than the size of a given rectangle, the
//                result will be CGRectZero.
// edge         - The edge from which to trim.
//
// Returns a signal of CGRect remainders.
- (RACSignal *)remainderAfterSlicingAmount:(RACSignal *)amountSignal fromEdge:(CGRectEdge)edge;

// Invokes -divideWithAmount:padding:fromEdge: with a constant padding of 0.
- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal fromEdge:(CGRectEdge)edge;

// Divides each CGRect into two component rectangles, skipping an amount of
// padding between them.
//
// sliceAmountSignal - A signal of CGFloat values, representing the number of
//                     points to include in the slice rectangle, starting from
//                     `edge`. If greater than the size of a given rectangle,
//                     the slice will be the entire rectangle, and the remainder
//                     will be CGRectZero.
// paddingSignal     - A signal of CGFloat values, representing the number of
//                     points of padding to omit between the slice and remainder
//                     rectangles. If the padding plus the slice amount is
//                     greater than or equal to the size of a given rectangle,
//                     the remainder will be CGRectZero. 
// edge              - The edge from which division begins, proceeding toward the
//                     opposite edge.
//
// Returns a RACTuple containing two signals, which will send the slices and
// remainders, respectively.
- (RACTuple *)divideWithAmount:(RACSignal *)sliceAmountSignal padding:(RACSignal *)paddingSignal fromEdge:(CGRectEdge)edge;

// Sends the maximum value sent by any of the given signals.
//
// signals - An array of <RACSignal> objects. Each signal should contain
//           NSNumber values. When any signal sends a value, the returned signal
//           will send the new maximum.
//
// Returns a signal which sends NSNumber maximum values.
+ (RACSignal *)max:(NSArray *)signals;

// Sends the minimum value sent by any of the given signals.
//
// signals - An array of <RACSignal> objects. Each signal should contain
//           NSNumber values. When any signal sends a value, the returned signal
//           will send the new minimum.
//
// Returns a signal which sends NSNumber minimum values.
+ (RACSignal *)min:(NSArray *)signals;

// Wraps every next in an animation block, using the default duration and
// animation curve.
//
// Binding the resulting signal to a view property will result in updates to
// that property (that originate from the signal) being automatically animated.
//
// Returns a signal which animates the sending of its values. Deferring the
// signal's events or having them delivered on another thread is considered
// undefined behavior.
- (RACSignal *)animate;

// Invokes -animateWithDuration:curve: with a curve of RCLAnimationCurveDefault.
- (RACSignal *)animateWithDuration:(NSTimeInterval)duration;

// Behaves like -animate, but uses the given duration and animation curve
// instead of the defaults.
- (RACSignal *)animateWithDuration:(NSTimeInterval)duration curve:(RCLAnimationCurve)curve;

@end
