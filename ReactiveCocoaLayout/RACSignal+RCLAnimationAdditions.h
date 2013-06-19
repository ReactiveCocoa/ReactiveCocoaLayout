//
//  RACSignal+RCLAnimationAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-01-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
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
    typedef enum {
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

@interface RACSignal (RCLAnimationAdditions)

// Wraps every next in an animation block, using the default duration and
// animation curve.
//
// Binding the resulting signal to a view property will result in updates to
// that property (that originate from the signal) being automatically animated.
//
// To delay an animation, use -[RACSignal delay:] or -[RACSignal throttle:] on
// the receiver _before_ applying -animate. Because the aforementioned methods
// delay delivery of `next`s, applying them _after_ -animate will cause values
// to be delivered outside of any animation block.
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

// Injects side effects whenever an animation triggered by the receiver
// completes, or whenever the receiver sends a non-animated value.
//
// This is equivalent to -doNext: if applied to a signal that does not animate.
//
// block - A block to execute when animations complete or non-animated values
//         are sent. The block will be passed the non-animated value, or the
//         value that triggered the animation which is now complete. This block
//         must not be nil.
//
// Returns a signal which forwards all the events of the receiver.
- (RACSignal *)doAnimationCompleted:(void (^)(id))block;

// Completes only after the animated signal has completed *and* all running
// animations have completed.
- (RACSignal *)completeAfterAnimations;

@end
