//
//  NSView+RCLObservationAdditions.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol RCLSignal;

@interface NSView (RCLObservationAdditions)

- (id<RCLSignal>)rcl_bounds;
- (id<RCLSignal>)rcl_frame;

@end
