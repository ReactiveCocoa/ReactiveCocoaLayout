//
//  ViewExamples.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-17.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "TestView.h"
#import "ViewExamples.h"

NSString * const ViewExamples = @"ViewExamples";

SharedExampleGroupsBegin(ViewExamples)

sharedExamplesFor(ViewExamples, ^{
	__block CGRect initialFrame;
	__block CGRect initialBounds;

	__block TestView *view;

	beforeEach(^{
		initialFrame = CGRectMake(100, 200, 300, 400);
		initialBounds = CGRectMake(0, 0, 300, 400);

		view = [[TestView alloc] initWithFrame:initialFrame];
		expect(view).notTo.beNil();
	});

	it(@"should send values on rcl_boundsSignal", ^{
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

	it(@"should send values on rcl_frameSignal", ^{
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

	it(@"should send values on rcl_intrinsicContentSizeSignal", ^{
		__block NSValue *lastValue = nil;
		[view.rcl_intrinsicContentSizeSignal subscribeNext:^(NSValue *value) {
			expect(value).to.beKindOf(NSValue.class);
			lastValue = value;
		}];

		expect(lastValue).notTo.beNil();
		expect(lastValue.med_sizeValue).to.equal(CGSizeZero);

		CGSize newSize = CGSizeMake(5, 10);
		[view invalidateAndSetIntrinsicContentSize:newSize];
		expect(lastValue.med_sizeValue).to.equal(newSize);
	});

	it(@"should send values on rcl_intrinsicBoundsSignal", ^{
		__block NSValue *lastValue = nil;
		[view.rcl_intrinsicBoundsSignal subscribeNext:^(NSValue *value) {
			expect(value).to.beKindOf(NSValue.class);
			lastValue = value;
		}];

		expect(lastValue).notTo.beNil();
		expect(lastValue.med_rectValue).to.equal(CGRectZero);

		CGSize newSize = CGSizeMake(5, 10);
		[view invalidateAndSetIntrinsicContentSize:newSize];
		expect(lastValue.med_rectValue).to.equal(CGRectMake(0, 0, 5, 10));
	});

	it(@"should send values on rcl_alignmentRectSignal", ^{
		__block NSValue *lastValue = nil;
		[view.rcl_alignmentRectSignal subscribeNext:^(NSValue *value) {
			expect(value).to.beKindOf(NSValue.class);
			lastValue = value;
		}];

		expect(lastValue).notTo.beNil();
		expect(lastValue.med_rectValue).to.equal(CGRectMake(101, 202, 298, 396));

		CGRect newFrame = CGRectMake(10, 20, 30, 40);
		view.frame = newFrame;
		expect(lastValue.med_rectValue).to.equal(CGRectMake(11, 22, 28, 36));
	});

	it(@"should bind the alignment rect", ^{
		RACSubject *subject = [RACSubject subject];

		RACDisposable *disposable = [view rcl_bindAlignmentRectToSignal:subject];
		expect(disposable).notTo.beNil();

		expect(view.frame).to.equal(initialFrame);

		[subject sendNext:MEDBox(CGRectMake(1, 2, 8, 6))];
		expect(view.frame).to.equal(CGRectMake(0, 0, 10, 10));

		[subject sendNext:MEDBox(CGRectMake(5, 5, 10, 10))];
		expect(view.frame).to.equal(CGRectMake(4, 3, 12, 14));
	});
});

SharedExampleGroupsEnd
