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

sharedExamplesFor(ViewExamples, ^(NSDictionary *_) {
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

		CGRect newBounds = CGRectMake(0, 0, 35, 45);
		view.frame = CGRectMake(10, 20, 35, 45);
		expect(view.bounds).to.equal(newBounds);
		expect(lastValue.med_rectValue).to.equal(newBounds);

		newBounds = CGRectMake(0, 0, 30, 40);
		view.bounds = newBounds;
		expect(lastValue.med_rectValue).to.equal(newBounds);
	});

	it(@"should complete rcl_boundsSignal when deallocated", ^{
		__block BOOL completed = NO;

		@autoreleasepool {
			TestView *view __attribute__((objc_precise_lifetime)) = [[TestView alloc] initWithFrame:initialFrame];
			[view.rcl_boundsSignal subscribeCompleted:^{
				completed = YES;
			}];

			expect(completed).to.beFalsy();
		}

		expect(completed).to.beTruthy();
	});

	it(@"should defer reading initial bounds", ^{
		RACSignal *boundsSignal = view.rcl_boundsSignal;

		CGRect newBounds = CGRectMake(0, 0, 30, 40);
		view.bounds = newBounds;

		expect([[boundsSignal first] med_rectValue]).to.equal(newBounds);
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

	it(@"should complete rcl_frameSignal when deallocated", ^{
		__block BOOL completed = NO;

		@autoreleasepool {
			TestView *view __attribute__((objc_precise_lifetime)) = [[TestView alloc] initWithFrame:initialFrame];
			[view.rcl_frameSignal subscribeCompleted:^{
				completed = YES;
			}];

			expect(completed).to.beFalsy();
		}

		expect(completed).to.beTruthy();
	});

	it(@"should defer reading initial frame", ^{
		RACSignal *frameSignal = view.rcl_frameSignal;

		CGRect newFrame = CGRectMake(10, 20, 30, 40);
		view.frame = newFrame;

		expect([[frameSignal first] med_rectValue]).to.equal(newFrame);
	});

	describe(@"intrinsic size signals", ^{
		__block id lastValue;
		__block void (^subscribeToSignal)(RACSignal *);

		__block CGSize newSize;
		__block void (^setNewSize)(void);

		beforeEach(^{
			lastValue = nil;

			subscribeToSignal = [^(RACSignal *signal) {
				[signal subscribeNext:^(id value) {
					lastValue = value;
				}];

				expect(lastValue).notTo.beNil();
			} copy];

			newSize = CGSizeMake(5, 10);
			setNewSize = [^{
				[view invalidateAndSetIntrinsicContentSize:newSize];
			} copy];
		});

		it(@"should send values on rcl_intrinsicContentSizeSignal", ^{
			subscribeToSignal(view.rcl_intrinsicContentSizeSignal);
			expect([lastValue med_sizeValue]).to.equal(CGSizeZero);

			setNewSize();
			expect([lastValue med_sizeValue]).to.equal(newSize);
		});

		it(@"should complete rcl_intrinsicContentSizeSignal when deallocated", ^{
			__block BOOL completed = NO;

			@autoreleasepool {
				TestView *view __attribute__((objc_precise_lifetime)) = [[TestView alloc] initWithFrame:initialFrame];
				[view.rcl_intrinsicContentSizeSignal subscribeCompleted:^{
					completed = YES;
				}];

				expect(completed).to.beFalsy();
			}

			expect(completed).to.beTruthy();
		});

		it(@"should defer intrinsic content size", ^{
			RACSignal *sizeSignal = view.rcl_intrinsicContentSizeSignal;

			setNewSize();
			expect([[sizeSignal first] med_sizeValue]).to.equal(newSize);
		});

		it(@"should send values on rcl_intrinsicBoundsSignal", ^{
			subscribeToSignal(view.rcl_intrinsicBoundsSignal);
			expect([lastValue med_rectValue]).to.equal(CGRectZero);

			setNewSize();
			expect([lastValue med_rectValue]).to.equal(CGRectMake(0, 0, newSize.width, newSize.height));
		});

		it(@"should send values on rcl_intrinsicWidthSignal", ^{
			subscribeToSignal(view.rcl_intrinsicWidthSignal);
			expect(lastValue).to.equal(@0);

			setNewSize();
			expect([lastValue doubleValue]).to.beCloseTo(newSize.width);
		});

		it(@"should send values on rcl_intrinsicHeightSignal", ^{
			subscribeToSignal(view.rcl_intrinsicHeightSignal);
			expect(lastValue).to.equal(@0);

			setNewSize();
			expect([lastValue doubleValue]).to.beCloseTo(newSize.height);
		});
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

	it(@"should read rcl_alignmentRect", ^{
		expect(view.rcl_alignmentRect).to.equal(CGRectMake(101, 202, 298, 396));

		CGRect newFrame = CGRectMake(10, 20, 30, 40);
		view.frame = newFrame;
		expect(view.rcl_alignmentRect).to.equal(CGRectMake(11, 22, 28, 36));
	});

	it(@"should bind rcl_alignmentRect", ^{
		RACSubject *subject = [RACSubject subject];

		RAC(view, rcl_alignmentRect) = subject;
		expect(view.frame).to.equal(initialFrame);

		[subject sendNext:MEDBox(CGRectMake(1, 2, 8, 6))];
		expect(view.frame).to.equal(CGRectMake(0, 0, 10, 10));

		[subject sendNext:MEDBox(CGRectMake(5, 5, 10, 10))];
		expect(view.frame).to.equal(CGRectMake(4, 3, 12, 14));
	});
});

SharedExampleGroupsEnd
