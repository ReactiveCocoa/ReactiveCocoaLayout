//
//  RACSignalRCLGeometryAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(RACSignalRCLGeometryAdditions)

__block RACSequence *rects;
__block RACSequence *sizes;
__block RACSequence *points;

__block RACSequence *widths;
__block RACSequence *heights;

__block RACSequence *minXs;
__block RACSequence *minYs;

__block RACSequence *centerXs;
__block RACSequence *centerYs;

__block RACSequence *maxXs;
__block RACSequence *maxYs;

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

	minXs = [points map:^(NSValue *value) {
		return @(value.med_pointValue.x);
	}];

	minYs = [points map:^(NSValue *value) {
		return @(value.med_pointValue.y);
	}];

	centerXs = [RACSequence zip:@[ minXs, widths ] reduce:^(NSNumber *x, NSNumber *width) {
		return @(x.doubleValue + width.doubleValue / 2);
	}];

	centerYs = [RACSequence zip:@[ minYs, heights ] reduce:^(NSNumber *y, NSNumber *height) {
		return @(y.doubleValue + height.doubleValue / 2);
	}];

	maxXs = [RACSequence zip:@[ minXs, widths ] reduce:^(NSNumber *x, NSNumber *width) {
		return @(x.doubleValue + width.doubleValue);
	}];

	maxYs = [RACSequence zip:@[ minYs, heights ] reduce:^(NSNumber *y, NSNumber *height) {
		return @(y.doubleValue + height.doubleValue);
	}];
});

describe(@"signal of CGRects", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = rects.signal;
	});

	it(@"should map to sizes", ^{
		expect(signal.size.sequence).to.equal(sizes);
	});

	it(@"should map to origins", ^{
		expect(signal.origin.sequence).to.equal(points);
	});

	it(@"should map to center points", ^{
		RACSequence *expected = [RACSequence zip:@[ centerXs, centerYs ] reduce:^(NSNumber *x, NSNumber *y) {
			return MEDBox(CGPointMake(x.doubleValue, y.doubleValue));
		}];

		expect(signal.center.sequence).to.equal(expected);
	});

	it(@"should map to widths", ^{
		expect(signal.width.sequence).to.equal(widths);
	});

	it(@"should map to heights", ^{
		expect(signal.height.sequence).to.equal(heights);
	});

	it(@"should map to positions of a specific edge", ^{
		RACSignal *minX = [signal positionOfEdge:[RACSignal return:@(CGRectMinXEdge)]];
		expect(minX.sequence).to.equal(minXs);

		RACSignal *minY = [signal positionOfEdge:[RACSignal return:@(CGRectMinYEdge)]];
		expect(minY.sequence).to.equal(minYs);
	});

	it(@"should map to minX values", ^{
		expect(signal.minX.sequence).to.equal(minXs);
	});

	it(@"should map to minY values", ^{
		expect(signal.minY.sequence).to.equal(minYs);
	});

	it(@"should map to centerX values", ^{
		expect(signal.centerX.sequence).to.equal(centerXs);
	});

	it(@"should map to centerY values", ^{
		expect(signal.centerY.sequence).to.equal(centerYs);
	});

	it(@"should map to maxX values", ^{
		expect(signal.maxX.sequence).to.equal(maxXs);
	});

	it(@"should map to maxY values", ^{
		expect(signal.maxY.sequence).to.equal(maxYs);
	});

	it(@"should map to leading and trailing", ^{
		RACSequence *leading = signal.leading.sequence;
		RACSequence *trailing = signal.trailing.sequence;

		if ([leading isEqual:minXs]) {
			expect(trailing).to.equal(maxXs);
		} else {
			expect(leading).to.equal(maxXs);
			expect(trailing).to.equal(minXs);
		}
	});

	it(@"should inset", ^{
		RACSignal *result = [signal insetWidth:[RACSignal return:@3] height:[RACSignal return:@5]];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(13, 15, 14, 10)),
			MEDBox(CGRectMake(13, 25, 24, 30)),
			MEDBox(CGRectMake(28, 20, 39, 25)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should slice", ^{
		RACSignal *result = [signal sliceWithAmount:[RACSignal return:@5] fromEdge:CGRectMinXEdge];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(10, 10, 5, 20)),
			MEDBox(CGRectMake(10, 20, 5, 40)),
			MEDBox(CGRectMake(25, 15, 5, 35)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should return a remainder", ^{
		RACSignal *result = [signal remainderAfterSlicingAmount:[RACSignal return:@5] fromEdge:CGRectMinYEdge];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(10, 15, 20, 15)),
			MEDBox(CGRectMake(10, 25, 30, 35)),
			MEDBox(CGRectMake(25, 20, 45, 30)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should grow", ^{
		RACSignal *result = [signal growEdge:CGRectMaxXEdge byAmount:[RACSignal return:@5]];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(10, 10, 25, 20)),
			MEDBox(CGRectMake(10, 20, 35, 40)),
			MEDBox(CGRectMake(25, 15, 50, 35)),
		];

		expect(result.sequence).to.equal(expectedRects.rac_sequence);
	});

	it(@"should divide into two rects", ^{
		RACTupleUnpack(RACSignal *slices, RACSignal *remainders) = [signal divideWithAmount:[RACSignal return:@15] fromEdge:CGRectMinXEdge];

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

	it(@"should divide into two rects with padding", ^{
		RACTupleUnpack(RACSignal *slices, RACSignal *remainders) = [signal divideWithAmount:[RACSignal return:@15] padding:[RACSignal return:@3] fromEdge:CGRectMinXEdge];

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

	it(@"should be returned from +rectsWithX:Y:width:height:", ^{
		RACSubject *subject = [RACSubject subject];

		RACSignal *constructedSignal = [RACSignal rectsWithX:subject Y:subject width:subject height:subject];
		NSMutableArray *values = [NSMutableArray array];

		[constructedSignal subscribeNext:^(id value) {
			[values addObject:value];
		}];

		[subject sendNext:@0];
		[subject sendNext:@5];

		NSArray *expected = @[
			MEDBox(CGRectMake(0, 0, 0, 0)),
			MEDBox(CGRectMake(5, 0, 0, 0)),
			MEDBox(CGRectMake(5, 5, 0, 0)),
			MEDBox(CGRectMake(5, 5, 5, 0)),
			MEDBox(CGRectMake(5, 5, 5, 5)),
		];

		expect(values).to.equal(expected);
	});

	it(@"should be returned from +rectsWithOrigin:size:", ^{
		RACSubject *originSubject = [RACSubject subject];
		RACSubject *sizeSubject = [RACSubject subject];

		RACSignal *constructedSignal = [RACSignal rectsWithOrigin:originSubject size:sizeSubject];
		NSMutableArray *values = [NSMutableArray array];

		[constructedSignal subscribeNext:^(id value) {
			[values addObject:value];
		}];

		[originSubject sendNext:MEDBox(CGPointMake(0, 0))];
		[sizeSubject sendNext:MEDBox(CGSizeMake(0, 0))];
		[sizeSubject sendNext:MEDBox(CGSizeMake(5, 5))];

		NSArray *expected = @[
			MEDBox(CGRectMake(0, 0, 0, 0)),
			MEDBox(CGRectMake(0, 0, 5, 5)),
		];

		expect(values).to.equal(expected);
	});

	it(@"should be returned from +rectsWithCenter:size:", ^{
		RACSubject *centerSubject = [RACSubject subject];
		RACSubject *sizeSubject = [RACSubject subject];

		RACSignal *constructedSignal = [RACSignal rectsWithCenter:centerSubject size:sizeSubject];
		NSMutableArray *values = [NSMutableArray array];

		[constructedSignal subscribeNext:^(id value) {
			[values addObject:value];
		}];

		[centerSubject sendNext:MEDBox(CGPointMake(0, 0))];
		[sizeSubject sendNext:MEDBox(CGSizeMake(0, 0))];
		[sizeSubject sendNext:MEDBox(CGSizeMake(2, 2))];
		[sizeSubject sendNext:MEDBox(CGSizeMake(5, 5))];

		NSArray *expected = @[
			MEDBox(CGRectMake(0, 0, 0, 0)),
			MEDBox(CGRectMake(-1, -1, 2, 2)),
			MEDBox(CGRectMake(-2.5, -2.5, 5, 5)),
		];

		expect(values).to.equal(expected);
	});

	it(@"should be returned from +rectsWithSize:", ^{
		RACSubject *sizeSubject = [RACSubject subject];

		RACSignal *constructedSignal = [RACSignal rectsWithSize:sizeSubject];
		NSMutableArray *values = [NSMutableArray array];

		[constructedSignal subscribeNext:^(id value) {
			[values addObject:value];
		}];

		[sizeSubject sendNext:MEDBox(CGSizeMake(0, 0))];
		[sizeSubject sendNext:MEDBox(CGSizeMake(5, 5))];

		NSArray *expected = @[
			MEDBox(CGRectMake(0, 0, 0, 0)),
			MEDBox(CGRectMake(0, 0, 5, 5)),
		];

		expect(values).to.equal(expected);
	});

	describe(@"position alignment", ^{
		__block RACSignal *position;
		
		beforeEach(^{
			position = [RACSignal return:@3];
		});

		it(@"should align minX to a specified position", ^{
			RACSignal *aligned = [signal alignEdge:[RACSignal return:@(CGRectMinXEdge)] toPosition:position];
			RACSequence *expected = @[
				MEDBox(CGRectMake(3, 10, 20, 20)),
				MEDBox(CGRectMake(3, 20, 30, 40)),
				MEDBox(CGRectMake(3, 15, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});

		it(@"should align minY to a specified position", ^{
			RACSignal *aligned = [signal alignEdge:[RACSignal return:@(CGRectMinYEdge)] toPosition:position];
			RACSequence *expected = @[
				MEDBox(CGRectMake(10, 3, 20, 20)),
				MEDBox(CGRectMake(10, 3, 30, 40)),
				MEDBox(CGRectMake(25, 3, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});

		it(@"should align centerX to a specified position", ^{
			RACSignal *aligned = [signal alignCenterX:position];
			RACSequence *expected = @[
				MEDBox(CGRectMake(-7, 10, 20, 20)),
				MEDBox(CGRectMake(-12, 20, 30, 40)),
				MEDBox(CGRectMake(-19.5, 15, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});

		it(@"should align centerY to a specified position", ^{
			RACSignal *aligned = [signal alignCenterY:position];
			RACSequence *expected = @[
				MEDBox(CGRectMake(10, -7, 20, 20)),
				MEDBox(CGRectMake(10, -17, 30, 40)),
				MEDBox(CGRectMake(25, -14.5, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});

		it(@"should align center point to a specified position", ^{
			CGPoint center = CGPointMake(5, 10);
			RACSignal *aligned = [signal alignCenter:[RACSignal return:MEDBox(center)]];

			RACSequence *expected = @[
				MEDBox(CGRectMake(-5, 0, 20, 20)),
				MEDBox(CGRectMake(-10, -10, 30, 40)),
				MEDBox(CGRectMake(-17.5, -7.5, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});

		it(@"should align maxX to a specified position", ^{
			RACSignal *aligned = [signal alignEdge:[RACSignal return:@(CGRectMaxXEdge)] toPosition:position];
			RACSequence *expected = @[
				MEDBox(CGRectMake(-17, 10, 20, 20)),
				MEDBox(CGRectMake(-27, 20, 30, 40)),
				MEDBox(CGRectMake(-42, 15, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});

		it(@"should align maxY to a specified position", ^{
			RACSignal *aligned = [signal alignEdge:[RACSignal return:@(CGRectMaxYEdge)] toPosition:position];
			RACSequence *expected = @[
				MEDBox(CGRectMake(10, -17, 20, 20)),
				MEDBox(CGRectMake(10, -37, 30, 40)),
				MEDBox(CGRectMake(25, -32, 45, 35)),
			].rac_sequence;

			expect(aligned.sequence).to.equal(expected);
		});
	});

	describe(@"baseline alignment", ^{
		__block RACSignal *baseline1;
		__block RACSignal *baseline2;

		beforeEach(^{
			baseline1 = [RACSignal return:@2];
			baseline2 = [RACSignal return:@5];
		});

		#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
			it(@"should align to a baseline", ^{
				RACSignal *reference = [RACSignal return:MEDBox(CGRectMake(0, 30, 0, 15))];
				RACSignal *aligned = [signal alignBaseline:baseline1 toBaseline:baseline2 ofRect:reference];

				RACSequence *expected = @[
					MEDBox(CGRectMake(10, 22, 20, 20)),
					MEDBox(CGRectMake(10, 2, 30, 40)),
					MEDBox(CGRectMake(25, 7, 45, 35)),
				].rac_sequence;

				expect(aligned.sequence).to.equal(expected);
			});
		#elif TARGET_OS_MAC
			it(@"should align to a baseline", ^{
				RACSignal *reference = [RACSignal return:MEDBox(CGRectMake(0, 30, 0, 15))];
				RACSignal *aligned = [signal alignBaseline:baseline1 toBaseline:baseline2 ofRect:reference];

				RACSequence *expected = @[
					MEDBox(CGRectMake(10, 33, 20, 20)),
					MEDBox(CGRectMake(10, 33, 30, 40)),
					MEDBox(CGRectMake(25, 33, 45, 35)),
				].rac_sequence;

				expect(aligned.sequence).to.equal(expected);
			});
		#endif
	});
});

describe(@"signal of CGSizes", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = sizes.signal;
	});

	it(@"should map to widths", ^{
		expect(signal.width.sequence).to.equal(widths);
	});

	it(@"should map to heights", ^{
		expect(signal.height.sequence).to.equal(heights);
	});

	it(@"should be returned from +sizesWithWidth:height:", ^{
		RACSubject *subject = [RACSubject subject];

		RACSignal *constructedSignal = [RACSignal sizesWithWidth:subject height:subject];
		NSMutableArray *values = [NSMutableArray array];

		[constructedSignal subscribeNext:^(id value) {
			[values addObject:value];
		}];

		[subject sendNext:@0];
		[subject sendNext:@5];

		NSArray *expected = @[
			MEDBox(CGSizeMake(0, 0)),
			MEDBox(CGSizeMake(5, 0)),
			MEDBox(CGSizeMake(5, 5)),
		];

		expect(values).to.equal(expected);
	});
});

describe(@"signal of CGPoints", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = points.signal;
	});

	it(@"should map to minXs", ^{
		expect(signal.x.sequence).to.equal(minXs);
	});

	it(@"should map to minYs", ^{
		expect(signal.y.sequence).to.equal(minYs);
	});

	it(@"should be returned from +pointsWithX:Y:", ^{
		RACSubject *subject = [RACSubject subject];

		RACSignal *constructedSignal = [RACSignal pointsWithX:subject Y:subject];
		NSMutableArray *values = [NSMutableArray array];

		[constructedSignal subscribeNext:^(id value) {
			[values addObject:value];
		}];

		[subject sendNext:@0];
		[subject sendNext:@5];

		NSArray *expected = @[
			MEDBox(CGPointMake(0, 0)),
			MEDBox(CGPointMake(5, 0)),
			MEDBox(CGPointMake(5, 5)),
		];

		expect(values).to.equal(expected);
	});
});

describe(@"+min: and +max:", ^{
	__block NSArray *signals;

	beforeEach(^{
		signals = @[
			[widths signalWithScheduler:RACScheduler.immediateScheduler],
			[minYs signalWithScheduler:RACScheduler.immediateScheduler],
		];
	});

	it(@"should return maximums", ^{
		RACSignal *signal = [RACSignal max:signals];
		NSArray *expected = @[ @20, @30, @45, @45, @45, @45 ];
		expect(signal.sequence).to.equal(expected.rac_sequence);
	});

	it(@"should return minimums", ^{
		RACSignal *signal = [RACSignal min:signals];
		NSArray *expected = @[ @20, @20, @20, @10, @10, @10 ];
		expect(signal.sequence).to.equal(expected.rac_sequence);
	});
});

describe(@"mathematical operators", ^{
	__block RACSignal *numberA;
	__block RACSignal *numberB;

	__block RACSignal *pointA;
	__block RACSignal *pointB;

	__block RACSignal *sizeA;
	__block RACSignal *sizeB;

	beforeEach(^{
		numberA = [RACSignal return:@5];
		numberB = [RACSignal return:@2];

		pointA = [RACSignal return:MEDBox(CGPointMake(5, 10))];
		pointB = [RACSignal return:MEDBox(CGPointMake(1, 2))];

		sizeA = [RACSignal return:MEDBox(CGSizeMake(5, 10))];
		sizeB = [RACSignal return:MEDBox(CGSizeMake(1, 2))];
	});

	describe(@"-plus:", ^{
		it(@"should add two numbers", ^{
			expect([numberA plus:numberB].sequence).to.equal(@[ @7 ].rac_sequence);
		});

		it(@"should add two points", ^{
			CGPoint expected = CGPointMake(6, 12);
			expect([pointA plus:pointB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});

		it(@"should add two sizes", ^{
			CGSize expected = CGSizeMake(6, 12);
			expect([sizeA plus:sizeB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});
	});

	describe(@"-minus:", ^{
		it(@"should subtract two numbers", ^{
			expect([numberA minus:numberB].sequence).to.equal(@[ @3 ].rac_sequence);
		});

		it(@"should subtract two points", ^{
			CGPoint expected = CGPointMake(4, 8);
			expect([pointA minus:pointB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});

		it(@"should subtract two sizes", ^{
			CGSize expected = CGSizeMake(4, 8);
			expect([sizeA minus:sizeB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});
	});

	describe(@"-multipliedBy:", ^{
		it(@"should multiply two numbers", ^{
			expect([numberA multipliedBy:numberB].sequence).to.equal(@[ @10 ].rac_sequence);
		});

		it(@"should multiply two points", ^{
			CGPoint expected = CGPointMake(5, 20);
			expect([pointA multipliedBy:pointB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});

		it(@"should multiply two sizes", ^{
			CGSize expected = CGSizeMake(5, 20);
			expect([sizeA multipliedBy:sizeB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});
	});

	describe(@"-dividedBy:", ^{
		it(@"should divide two numbers", ^{
			expect([numberA dividedBy:numberB].sequence).to.equal(@[ @2.5 ].rac_sequence);
		});

		it(@"should divide two points", ^{
			CGPoint expected = CGPointMake(5, 5);
			expect([pointA dividedBy:pointB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});

		it(@"should divide two sizes", ^{
			CGSize expected = CGSizeMake(5, 5);
			expect([sizeA dividedBy:sizeB].sequence).to.equal(@[ MEDBox(expected) ].rac_sequence);
		});
	});
});

SpecEnd
