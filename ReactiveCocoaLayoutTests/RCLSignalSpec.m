//
//  RCLSignalSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(RCLSignal)

__block RACSequence *rects;
__block RACSequence *sizes;
__block RACSequence *points;

__block RACSequence *widths;
__block RACSequence *heights;

__block RACSequence *xs;
__block RACSequence *ys;

beforeEach(^{
	rects = @[
		MEDBox(CGRectMake(10, 10, 20, 20)),
		MEDBox(CGRectMake(10, 20, 30, 40)),
		MEDBox(CGRectMake(25, 15, 45, 35)),
	].rac_sequence;

	sizes = [rects map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.size);
	}];

	widths = [sizes map:^(NSValue *value) {
		return @(value.med_sizeValue.width);
	}];

	heights = [sizes map:^(NSValue *value) {
		return @(value.med_sizeValue.height);
	}];

	points = [rects map:^(NSValue *value) {
		return MEDBox(value.med_rectValue.origin);
	}];

	xs = [points map:^(NSValue *value) {
		return @(value.med_pointValue.x);
	}];

	ys = [points map:^(NSValue *value) {
		return @(value.med_pointValue.y);
	}];
});

describe(@"signal of CGRects", ^{
	__block id<RCLSignal> signal;

	beforeEach(^{
		signal = (id)[rects signalWithScheduler:RACScheduler.immediateScheduler];
	});

	it(@"should map to sizes", ^{
		expect(signal.size.sequence).to.equal(sizes);
	});

	it(@"should map to origins", ^{
		expect(signal.origin.sequence).to.equal(points);
	});

	it(@"should inset", ^{
		id<RCLSignal> result = [signal insetWidth:3 height:5];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(13, 15, 14, 10)),
			MEDBox(CGRectMake(13, 25, 24, 30)),
			MEDBox(CGRectMake(28, 20, 39, 25)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should slice", ^{
		id<RCLSignal> result = [signal sliceWithAmount:5 fromEdge:CGRectMinXEdge];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(10, 10, 5, 20)),
			MEDBox(CGRectMake(10, 20, 5, 40)),
			MEDBox(CGRectMake(25, 15, 5, 35)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should return a remainder", ^{
		id<RCLSignal> result = [signal remainderAfterSlicingAmount:5 fromEdge:CGRectMinYEdge];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(10, 15, 20, 15)),
			MEDBox(CGRectMake(10, 25, 30, 35)),
			MEDBox(CGRectMake(25, 20, 45, 30)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should divide", ^{
		RACTupleUnpack(id<RCLSignal> slices, id<RCLSignal> remainders) = [signal divideWithAmount:15 fromEdge:CGRectMinXEdge];

		NSArray *expectedSlices = @[
			MEDBox(CGRectMake(10, 10, 15, 20)),
			MEDBox(CGRectMake(10, 20, 15, 40)),
			MEDBox(CGRectMake(25, 15, 15, 35)),
		];

		NSArray *expectedRemainders = @[
			MEDBox(CGRectMake(25, 10, 5, 20)),
			MEDBox(CGRectMake(25, 20, 15, 40)),
			MEDBox(CGRectMake(40, 15, 30, 35)),
		];

		expect(slices.sequence).to.equal(expectedSlices.rac_sequence);
		expect(remainders.sequence).to.equal(expectedRemainders.rac_sequence);
	});

	it(@"should divide with padding", ^{
		RACTupleUnpack(id<RCLSignal> slices, id<RCLSignal> remainders) = [signal divideWithAmount:15 padding:3 fromEdge:CGRectMinXEdge];

		NSArray *expectedSlices = @[
			MEDBox(CGRectMake(10, 10, 15, 20)),
			MEDBox(CGRectMake(10, 20, 15, 40)),
			MEDBox(CGRectMake(25, 15, 15, 35)),
		];

		NSArray *expectedRemainders = @[
			MEDBox(CGRectMake(28, 10, 2, 20)),
			MEDBox(CGRectMake(28, 20, 12, 40)),
			MEDBox(CGRectMake(43, 15, 27, 35)),
		];

		expect(slices.sequence).to.equal(expectedSlices.rac_sequence);
		expect(remainders.sequence).to.equal(expectedRemainders.rac_sequence);
	});
});

describe(@"signal of CGSizes", ^{
	__block id<RCLSignal> signal;

	beforeEach(^{
		signal = (id)[sizes signalWithScheduler:RACScheduler.immediateScheduler];
	});

	it(@"should map to widths", ^{
		expect(signal.width.sequence).to.equal(widths);
	});

	it(@"should map to heights", ^{
		expect(signal.height.sequence).to.equal(heights);
	});
});

describe(@"signal of CGPoints", ^{
	__block id<RCLSignal> signal;

	beforeEach(^{
		signal = (id)[points signalWithScheduler:RACScheduler.immediateScheduler];
	});

	it(@"should map to Xs", ^{
		expect(signal.x.sequence).to.equal(xs);
	});

	it(@"should map to Ys", ^{
		expect(signal.y.sequence).to.equal(ys);
	});
});

SpecEnd
