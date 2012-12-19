//
//  View+RCLAutoLayoutObservationAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-17.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "View+RCLAutoLayoutObservationAdditions.h"
#import "RACSignal+RCLGeometryAdditions.h"
#import <objc/runtime.h>

// Associated with a RACSubject which sends -intrinsicContentSize whenever
// -invalidateIntrinsicContentSize is invoked.
static void *IntrinsicContentSizeSubjectKey = &IntrinsicContentSizeSubjectKey;

static void (*oldInvalidateIntrinsicContentSize)(id, SEL);
static void newInvalidateIntrinsicContentSize(id self, SEL _cmd) {
	oldInvalidateIntrinsicContentSize(self, _cmd);

	RACSubject *subject = objc_getAssociatedObject(self, IntrinsicContentSizeSubjectKey);
	if (subject == nil) return;

	[subject sendNext:MEDBox([self intrinsicContentSize])];
}

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
@implementation UIView (RCLAutoLayoutObservationAdditions)
#elif TARGET_OS_MAC
@implementation NSView (RCLAutoLayoutObservationAdditions)
#endif

+ (void)load {
	SEL selector = @selector(invalidateIntrinsicContentSize);

	Method method = class_getInstanceMethod(self, selector);
	NSAssert(method != NULL, @"Could not find %@ on %@", NSStringFromSelector(selector), self);

	oldInvalidateIntrinsicContentSize = (__typeof__(oldInvalidateIntrinsicContentSize))method_getImplementation(method);
	class_replaceMethod(self, selector, (IMP)&newInvalidateIntrinsicContentSize, method_getTypeEncoding(method));
}

- (RACSignal *)rcl_intrinsicContentSizeSignal {
	RACSubject *subject = objc_getAssociatedObject(self, IntrinsicContentSizeSubjectKey);
	if (subject == nil) {
		subject = [RACSubject subject];
		objc_setAssociatedObject(self, IntrinsicContentSizeSubjectKey, subject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return [subject startWith:MEDBox(self.intrinsicContentSize)];
}

- (RACSignal *)rcl_intrinsicBoundsSignal {
	return [RACSignal rectsWithSize:self.rcl_intrinsicContentSizeSignal];
}

@end
