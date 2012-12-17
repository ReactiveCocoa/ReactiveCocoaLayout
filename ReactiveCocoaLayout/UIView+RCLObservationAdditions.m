//
//  UIView+RCLObservationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "UIView+RCLObservationAdditions.h"

@implementation UIView (RCLObservationAdditions)

// FIXME: These properties aren't actually declared as KVO-compliant by UIKit.
// Here be dragons?
- (id)rcl_boundsSignal {
	return RACAbleWithStart(self.bounds);
}

- (id)rcl_frameSignal {
	return RACAbleWithStart(self.frame);
}

@end
