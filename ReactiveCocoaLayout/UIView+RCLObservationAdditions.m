//
//  UIView+RCLObservationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "UIView+RCLObservationAdditions.h"
#import "RACSignal+RCLSignalAdditions.h"
#import <objc/runtime.h>

// Associated with a RACSubject which sends -intrinsicContentSize whenever
// -invalidateIntrinsicContentSize is invoked.
static void *UIViewIntrinsicContentSizeSubjectKey = &UIViewIntrinsicContentSizeSubjectKey;

static void (*oldInvalidateIntrinsicContentSize)(UIView *, SEL);
static void newInvalidateIntrinsicContentSize(UIView *self, SEL _cmd) {
	oldInvalidateIntrinsicContentSize(self, _cmd);

	RACSubject *subject = objc_getAssociatedObject(self, UIViewIntrinsicContentSizeSubjectKey);
	if (subject == nil) return;

	[subject sendNext:MEDBox(self.intrinsicContentSize)];
}

@implementation UIView (RCLObservationAdditions)

+ (void)load {
	SEL selector = @selector(invalidateIntrinsicContentSize);

	Method method = class_getInstanceMethod(self, selector);
	NSAssert(method != NULL, @"Could not find %@ on %@", NSStringFromSelector(selector), self);

	oldInvalidateIntrinsicContentSize = (__typeof__(oldInvalidateIntrinsicContentSize))method_getImplementation(method);
	class_replaceMethod(self, selector, (IMP)&newInvalidateIntrinsicContentSize, method_getTypeEncoding(method));
}

// FIXME: These properties aren't actually declared as KVO-compliant by UIKit.
// Here be dragons?
- (id)rcl_boundsSignal {
	return RACAbleWithStart(self.bounds);
}

- (id)rcl_frameSignal {
	return RACAbleWithStart(self.frame);
}

- (id<RCLSignal>)rcl_intrinsicContentSizeSignal {
	RACSubject *subject = objc_getAssociatedObject(self, UIViewIntrinsicContentSizeSubjectKey);
	if (subject == nil) {
		subject = [RACSubject subject];
		objc_setAssociatedObject(self, UIViewIntrinsicContentSizeSubjectKey, subject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return [subject startWith:MEDBox(self.intrinsicContentSize)];
}

@end
