//
//  NSView+RCLObservationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSView+RCLObservationAdditions.h"
#import "NSNotificationCenter+RACSupport.h"

@implementation NSView (RCLObservationAdditions)

- (id)rcl_bounds {
	self.postsBoundsChangedNotifications = YES;
	return [[[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewBoundsDidChangeNotification object:self]
		map:^(NSNotification *notification) {
			NSView *view = notification.object;
			return [NSValue valueWithRect:view.bounds];
		}]
		startWith:[NSValue valueWithRect:self.bounds]];
}

- (id)rcl_frame {
	self.postsFrameChangedNotifications = YES;
	return [[[NSNotificationCenter.defaultCenter rac_addObserverForName:NSViewFrameDidChangeNotification object:self]
		map:^(NSNotification *notification) {
			NSView *view = notification.object;
			return [NSValue valueWithRect:view.frame];
		}]
		startWith:[NSValue valueWithRect:self.frame]];
}

@end
