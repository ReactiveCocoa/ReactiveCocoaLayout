//
//  ViewExamples.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-17.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ViewExamples.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	#import <UIKit/UIKit.h>
	#define VIEW UIView
#elif TARGET_OS_MAC
	#import <AppKit/AppKit.h>
	#define VIEW NSView
#endif

NSString * const ViewExamples = @"ViewExamples";

SharedExampleGroupsBegin(ViewExamples)

sharedExamplesFor(ViewExamples, ^(VIEW * (^viewWithFrame)(CGRect)) {
	__block CGRect initialFrame;
	__block CGRect initialBounds;

	__block VIEW *view;

	beforeEach(^{
		initialFrame = CGRectMake(100, 200, 300, 400);
		initialBounds = CGRectMake(0, 0, 300, 400);

		view = viewWithFrame(initialFrame);
		expect(view).notTo.beNil();
	});

	it(@"should send values on rcl_boundsSignal when its bounds changes", ^{
		__block NSValue *lastValue = nil;
		[view.rcl_boundsSignal subscribeNext:^(NSValue *value) {
			expect(value).to.beKindOf(NSValue.class);
			lastValue = value;
		}];

		expect(lastValue).notTo.beNil();
		expect(lastValue.med_rectValue).to.equal(initialBounds);

		CGRect newBounds = CGRectMake(10, 20, 30, 40);
		view.bounds = newBounds;
		expect(lastValue.med_rectValue).to.equal(newBounds);
	});

	it(@"should send values on rcl_frameSignal when its frame changes", ^{
		__block NSValue *lastValue = nil;
		[view.rcl_frameSignal subscribeNext:^(NSValue *value) {
			expect(value).to.beKindOf(NSValue.class);
			lastValue = value;
		}];

		expect(lastValue).notTo.beNil();
		expect(lastValue.med_rectValue).to.equal(initialFrame);

		CGRect newFrame = CGRectMake(10, 20, 30, 40);
		view.frame = newFrame;
		expect(lastValue.med_rectValue).to.equal(newFrame);
	});
});

SharedExampleGroupsEnd
