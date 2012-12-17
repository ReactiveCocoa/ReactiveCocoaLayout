//
//  UIViewRCLObservationAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(UIViewRCLObservationAdditions)

__block CGRect initialFrame;
__block CGRect initialBounds;

__block UIView *view;

beforeEach(^{
	initialFrame = CGRectMake(100, 200, 300, 400);
	initialBounds = CGRectMake(0, 0, 300, 400);

	view = [[UIView alloc] initWithFrame:initialFrame];
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

SpecEnd
