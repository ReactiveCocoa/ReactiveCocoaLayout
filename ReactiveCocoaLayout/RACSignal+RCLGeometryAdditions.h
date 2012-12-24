//
//  RACSignal+RCLGeometryAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "View+RCLAutoLayoutAdditions.h"

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

// Determines whether the calling code is running from within -animate (or
// a variant thereof).
//
// This can be used to conditionalize behavior based on whether a signal
// somewhere in the chain is supposed to be animated.
//
// This function is thread-safe.
extern BOOL RCLIsInAnimatedSignal(void);

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

// Constructs rects from the given center and size signals.
//
// Returns a signal of CGRect values.
+ (RACSignal *)rectsWithCenter:(RACSignal *)centerSignal size:(RACSignal *)sizeSignal;

// Constructs rects from the given size signal. All of the rectangles will
// originate at (0, 0).
//
// This is useful for calculating bounds rectangles.
//
// Returns a signal of CGRect values.
+ (RACSignal *)rectsWithSize:(RACSignal *)sizeSignal;

// Maps CGRect values to their `size` fields.
//
// Returns a signal of CGSize values.
- (RACSignal *)size;

// Constructs sizes from the given width and height signals.
//
// Returns a signal of CGSize values.
+ (RACSignal *)sizesWithWidth:(RACSignal *)widthSignal height:(RACSignal *)heightSignal;

// Maps CGRect or CGSize values to their widths.
//
// Returns a signal of CGFloat values.
- (RACSignal *)width;

// Maps CGRect or CGSize values to their heights.
//
// Returns a signal of CGFloat values.
- (RACSignal *)height;

// Maps CGRect values to their `origin` fields.
//
// Returns a signal of CGPoint values.
- (RACSignal *)origin;

// Maps CGRect values to their exact center point.
//
// Returns a signal of CGPoint values.
- (RACSignal *)center;

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

// Maps CGRect values to the value of the specified layout attribute.
//
// attribute - The part of the rectangle to retrieve the value of. This
//             must not be NSLayoutAttributeBaseline.
//
// Returns a signal of CGFloat values.
- (RACSignal *)valueForAttribute:(NSLayoutAttribute)attribute;

// Maps CGRect values to the position of their left side.
//
// Returns a signal of CGFloat values.
- (RACSignal *)left;

// Maps CGRect values to the position of their right side.
//
// Returns a signal of CGFloat values.
- (RACSignal *)right;

// Maps CGRect values to the position of their top side.
//
// Returns a signal of CGFloat values.
- (RACSignal *)top;

// Maps CGRect values to the position of their bottom side.
//
// Returns a signal of CGFloat values.
- (RACSignal *)bottom;

// Maps CGRect values to their leading X position.
//
// Returns a signal of CGFloat values. The signal will automatically re-send
// when the user's current locale changes.
- (RACSignal *)leading;

// Maps CGRect values to their trailing X position.
//
// Returns a signal of CGFloat values. The signal will automatically re-send
// when the user's current locale changes.
- (RACSignal *)trailing;

// Maps CGRect values to their center X position.
//
// Returns a signal of CGFloat values.
- (RACSignal *)centerX;

// Maps CGRect values to their center Y position.
//
// Returns a signal of CGFloat values.
- (RACSignal *)centerY;

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

// For the given each of each CGRect, adds the given number of points sent from
// `amountSignal`.
//
// edge         - The edge to add to.
// amountSignal - A signal of CGFloat values, representing the number of points
//                to add.
//
// Returns a signal of enlarged CGRects.
- (RACSignal *)growEdge:(CGRectEdge)edge byAmount:(RACSignal *)amountSignal;

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

// Aligns the specified layout attribute of each CGRect to the values sent from
// the given signal.
//
// attribute   - The part of the rectangle to align. This must not be
//               NSLayoutAttributeBaseline (for which
//               -alignBaseline:toBaseline:ofRect: should be used instead).
// valueSignal - A signal of CGFloat values, representing the value to match the
//               specified attribute to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignAttribute:(NSLayoutAttribute)attribute to:(RACSignal *)valueSignal;

// Aligns the center of each CGRect to the CGPoints sent from the given signal.
//
// centerSignal - A signal of CGPoint values, representing the new center of the
//                rect.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignCenter:(RACSignal *)centerSignal;

// Aligns the left side of each CGRect to the values sent from the given signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the left side to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignLeft:(RACSignal *)positionSignal;

// Aligns the right side of each CGRect to the values sent from the given signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the right side to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignRight:(RACSignal *)positionSignal;

// Aligns the top side of each CGRect to the values sent from the given signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the top side to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignTop:(RACSignal *)positionSignal;

// Aligns the bottom side of each CGRect to the values sent from the given signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the bottom side to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignBottom:(RACSignal *)positionSignal;

// Aligns the leading side of each CGRect to the values sent from the given signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the leading side to.
//
// Returns a signal of aligned CGRect values. The signal will automatically
// re-send when the user's current locale changes.
- (RACSignal *)alignLeading:(RACSignal *)positionSignal;

// Aligns the trailing side of each CGRect to the values sent from the given signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the trailing side to.
//
// Returns a signal of aligned CGRect values. The signal will automatically
// re-send when the user's current locale changes.
- (RACSignal *)alignTrailing:(RACSignal *)positionSignal;

// Matches the width of each CGRect to the values sent from the given signal.
//
// amountSignal - A signal of CGFloat values, representing the new width.
//
// Returns a signal of resized CGRect values.
- (RACSignal *)alignWidth:(RACSignal *)amountSignal;

// Matches the height of each CGRect to the values sent from the given signal.
//
// amountSignal - A signal of CGFloat values, representing the new height.
//
// Returns a signal of resized CGRect values.
- (RACSignal *)alignHeight:(RACSignal *)amountSignal;

// Aligns the center X position of each CGRect to the values sent from the given
// signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the horizontal center to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignCenterX:(RACSignal *)positionSignal;

// Aligns the center Y position of each CGRect to the values sent from the given
// signal.
//
// positionSignal - A signal of CGFloat values, representing the position to align
//                  the vertical center to.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignCenterY:(RACSignal *)positionSignal;

// Aligns the baseline of each CGRect in the receiver to those of another signal.
//
// On iOS, baselines are considered to be relative to the maximum Y edge of the
// rectangle. On OS X, baselines are relative to the minimum Y edge.
//
// baselineSignal          - A signal of CGFloat values, representing baselines
//                           for the rects sent by the receiver.
// referenceBaselineSignal - A signal of CGFloat values, representing baselines
//                           for the rects sent by `referenceSentSignal`.
// referenceRectSignal     - A signal of CGRect values, to which the receiver's
//                           rects should be aligned.
//
// Returns a signal of aligned CGRect values.
- (RACSignal *)alignBaseline:(RACSignal *)baselineSignal toBaseline:(RACSignal *)referenceBaselineSignal ofRect:(RACSignal *)referenceRectSignal;

// Adds the values of the receiver and the given signal.
//
// The values may be CGFloats, CGSizes, or CGPoints, but both signals must send
// values of the same type.
//
// Returns a signal of sums, using the same type as the input values.
- (RACSignal *)plus:(RACSignal *)addendSignal;

// Subtracts the values of the given signal from those of the receiver.
//
// The values may be CGFloats, CGSizes, or CGPoints, but both signals must send
// values of the same type.
//
// Returns a signal of differences, using the same type as the input values.
- (RACSignal *)minus:(RACSignal *)subtrahendSignal;

// Multiplies the values of the receiver and the given signal.
//
// The values may be CGFloats, CGSizes, or CGPoints, but both signals must send
// values of the same type.
//
// Returns a signal of products, using the same type as the input values.
- (RACSignal *)multipliedBy:(RACSignal *)factorSignal;

// Divides the values of the receiver by those of the given signal.
//
// The values may be CGFloats, CGSizes, or CGPoints, but both signals must send
// values of the same type.
//
// Returns a signal of quotients, using the same type as the input values.
- (RACSignal *)dividedBy:(RACSignal *)denominatorSignal;

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
