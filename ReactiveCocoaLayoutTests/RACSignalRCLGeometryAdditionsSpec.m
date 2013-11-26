//
//  RACSignalRCLGeometryAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(RACSignalRCLGeometryAdditions)

__block NSArray *rects;
__block NSArray *sizes;
__block NSArray *points;

__block NSArray *widths;
__block NSArray *heights;

__block NSArray *minXs;
__block NSArray *minYs;

__block NSArray *centerXs;
__block NSArray *centerYs;

__block NSArray *maxXs;
__block NSArray *maxYs;

__block CGRectEdge leadingEdge;

beforeEach(^{
	rects = @[
		MEDBox(CGRectMake(10, 10, 20, 20)),
		MEDBox(CGRectMake(10, 20, 30, 40)),
		MEDBox(CGRectMake(25, 15, 45, 35)),
	];

	sizes = [[rects.rac_signal
		map:^(NSValue *value) {
			return MEDBox(value.med_rectValue.size);
		}]
		array];

	widths = [[sizes.rac_signal
		map:^(NSValue *value) {
			return @(value.med_sizeValue.width);
		}]
		array];

	heights = [[sizes.rac_signal
		map:^(NSValue *value) {
			return @(value.med_sizeValue.height);
		}]
		array];

	points = [[rects.rac_signal
		map:^(NSValue *value) {
			return MEDBox(value.med_rectValue.origin);
		}]
		array];

	minXs = [[points.rac_signal
		map:^(NSValue *value) {
			return @(value.med_pointValue.x);
		}]
		array];

	minYs = [[points.rac_signal
		map:^(NSValue *value) {
			return @(value.med_pointValue.y);
		}]
		array];

	centerXs = [[RACSignal
		zip:@[ minXs.rac_signal, widths.rac_signal ]
		reduce:^(NSNumber *x, NSNumber *width) {
			return @(x.doubleValue + width.doubleValue / 2);
		}]
		array];

	centerYs = [[RACSignal
		zip:@[ minYs.rac_signal, heights.rac_signal ]
		reduce:^(NSNumber *y, NSNumber *height) {
			return @(y.doubleValue + height.doubleValue / 2);
		}]
		array];

	maxXs = [[RACSignal
		zip:@[ minXs.rac_signal, widths.rac_signal ]
		reduce:^(NSNumber *x, NSNumber *width) {
			return @(x.doubleValue + width.doubleValue);
		}]
		array];

	maxYs = [[RACSignal
		zip:@[ minYs.rac_signal, heights.rac_signal ]
		reduce:^(NSNumber *y, NSNumber *height) {
			return @(y.doubleValue + height.doubleValue);
		}]
		array];

	NSNumber *leadingEdgeNum = [RACSignal.leadingEdgeSignal first];
	expect(leadingEdgeNum).notTo.beNil();

	leadingEdge = (CGRectEdge)leadingEdgeNum.unsignedIntegerValue;
});

describe(@"zeroes", ^{
	it(@"should return CGFloat zero", ^{
		expect([[RACSignal zero] first]).to.equal(@0);
	});

	it(@"should return CGRectZero", ^{
		expect([[[RACSignal zeroRect] first] med_rectValue]).to.equal(CGRectZero);
	});

	it(@"should return CGSizeZero", ^{
		expect([[[RACSignal zeroSize] first] med_sizeValue]).to.equal(CGSizeZero);
	});

	it(@"should return CGPointZero", ^{
		expect([[[RACSignal zeroPoint] first] med_pointValue]).to.equal(CGPointZero);
	});
});

describe(@"signal of CGRects", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = [rects.rac_signal subscribeOn:[RACScheduler scheduler]];
	});

	it(@"should map to sizes", ^{
		expect([signal.size array]).to.equal(sizes);
	});

	it(@"should map to origins", ^{
		expect([signal.origin array]).to.equal(points);
	});

	it(@"should map to center points", ^{
		NSArray *expected = [[RACSignal
			zip:@[ centerXs.rac_signal, centerYs.rac_signal ]
			reduce:^(NSNumber *x, NSNumber *y) {
				return MEDBox(CGPointMake(x.doubleValue, y.doubleValue));
			}]
			array];

		expect([signal.center array]).to.equal(expected);
	});

	describe(@"getting attribute values", ^{
		__block NSArray *tops;
		__block NSArray *bottoms;
		__block NSArray *leadings;
		__block NSArray *trailings;

		beforeEach(^{
			if (leadingEdge == CGRectMinXEdge) {
				leadings = minXs;
				trailings = maxXs;
			} else {
				leadings = maxXs;
				trailings = minXs;
			}

			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
			tops = minYs;
			bottoms = maxYs;
			#elif TARGET_OS_MAC
			tops = maxYs;
			bottoms = minYs;
			#endif
		});

		it(@"should map to NSLayoutAttributeLeft", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeLeft];
			expect([result array]).to.equal(minXs);

			expect([signal.left array]).to.equal(minXs);
		});

		it(@"should map to NSLayoutAttributeRight", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeRight];
			expect([result array]).to.equal(maxXs);

			expect([signal.right array]).to.equal(maxXs);
		});

		it(@"should map to NSLayoutAttributeTop", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeTop];
			expect([result array]).to.equal(tops);

			expect([signal.top array]).to.equal(tops);
		});

		it(@"should map to NSLayoutAttributeBottom", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeBottom];
			expect([result array]).to.equal(bottoms);

			expect([signal.bottom array]).to.equal(bottoms);
		});

		it(@"should map to NSLayoutAttributeWidth", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeWidth];
			expect([result array]).to.equal(widths);

			expect([signal.width array]).to.equal(widths);
		});

		it(@"should map to NSLayoutAttributeHeight", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeHeight];
			expect([result array]).to.equal(heights);

			expect([signal.height array]).to.equal(heights);
		});

		it(@"should map to NSLayoutAttributeCenterX", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeCenterX];
			expect([result array]).to.equal(centerXs);

			expect([signal.centerX array]).to.equal(centerXs);
		});

		it(@"should map to NSLayoutAttributeCenterY", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeCenterY];
			expect([result array]).to.equal(centerYs);

			expect([signal.centerY array]).to.equal(centerYs);
		});

		it(@"should map to NSLayoutAttributeLeading", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeLeading];
			expect([result array]).to.equal(leadings);

			expect([signal.leading array]).to.equal(leadings);
		});

		it(@"should map to NSLayoutAttributeTrailing", ^{
			RACSignal *result = [signal valueForAttribute:NSLayoutAttributeTrailing];
			expect([result array]).to.equal(trailings);

			expect([signal.trailing array]).to.equal(trailings);
		});
	});

	it(@"should inset width and height", ^{
		RACSignal *result = [signal insetWidth:[RACSignal return:@3] height:[RACSignal return:@5] nullRect:CGRectNull];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(13, 15, 14, 10)),
			MEDBox(CGRectMake(13, 25, 24, 30)),
			MEDBox(CGRectMake(28, 20, 39, 25)),
		];

		expect([result array]).to.equal(expectedRects);
	});
	
	describe(@"variable top, left, bottom, right insets", ^{
		__block NSArray *expectedRects;
		beforeEach(^{
			expectedRects = @[
				MEDBox(CGRectZero),
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				MEDBox(CGRectMake(20, 22, 0, 34)),
				MEDBox(CGRectMake(35, 17, 15, 29)),
#elif TARGET_OS_MAC
				MEDBox(CGRectMake(20, 24, 0, 34)),
				MEDBox(CGRectMake(35, 19, 15, 29)),
#endif
				];
		});
		
		it(@"should inset using top, left, bottom, right signals", ^{
			RACSignal *result = [signal insetTop:[RACSignal return:@2] left:[RACSignal return:@10] bottom:[RACSignal return:@4] right:[RACSignal return:@20] nullRect:CGRectZero];
			expect([result array]).to.equal(expectedRects);
		});
		
		it(@"should inset using an MEDEdgeInsets signal", ^{
			RACSignal *result = [signal insetBy:[RACSignal return:MEDBox(MEDEdgeInsetsMake(2, 10, 4, 20))] nullRect:CGRectZero];
			expect([result array]).to.equal(expectedRects);
		});
	});
	
	it(@"should use null rect for insets larger than the rect dimensions", ^{
		CGRect nullRect = CGRectMake(1, 2, 3, 4);
		RACSignal *result = [signal insetWidth:[RACSignal return:@11] height:[RACSignal return:@18] nullRect:nullRect];
		NSArray *expectedRects = @[
			MEDBox(nullRect),
			MEDBox(CGRectMake(21, 38, 8, 4)),
			MEDBox(nullRect),
		];
		
		expect([result array]).to.equal(expectedRects);
	});

	it(@"should slice", ^{
		RACSignal *result = [signal sliceWithAmount:[RACSignal return:@5] fromEdge:NSLayoutAttributeLeft];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(10, 10, 5, 20)),
			MEDBox(CGRectMake(10, 20, 5, 40)),
			MEDBox(CGRectMake(25, 15, 5, 35)),
		];

		expect([result array]).to.equal(expectedRects);
	});

	it(@"should return a remainder", ^{
		RACSignal *result = [signal remainderAfterSlicingAmount:[RACSignal return:@5] fromEdge:NSLayoutAttributeLeft];
		NSArray *expectedRects = @[
			MEDBox(CGRectMake(15, 10, 15, 20)),
			MEDBox(CGRectMake(15, 20, 25, 40)),
			MEDBox(CGRectMake(30, 15, 40, 35)),
		];

		expect([result array]).to.equal(expectedRects);
	});

	describe(@"extending attributes", ^{
		__block RACSignal *value;
		
		__block NSArray *extendedMinX;
		__block NSArray *extendedMaxX;
		__block NSArray *extendedMinY;
		__block NSArray *extendedMaxY;

		__block NSArray *extendedLeading;
		__block NSArray *extendedTrailing;
		
		beforeEach(^{
			value = [RACSignal return:@-5];

			extendedMinX = @[
				MEDBox(CGRectMake(15, 10, 15, 20)),
				MEDBox(CGRectMake(15, 20, 25, 40)),
				MEDBox(CGRectMake(30, 15, 40, 35)),
			];

			extendedMaxX = @[
				MEDBox(CGRectMake(10, 10, 15, 20)),
				MEDBox(CGRectMake(10, 20, 25, 40)),
				MEDBox(CGRectMake(25, 15, 40, 35)),
			];

			extendedMinY = @[
				MEDBox(CGRectMake(10, 15, 20, 15)),
				MEDBox(CGRectMake(10, 25, 30, 35)),
				MEDBox(CGRectMake(25, 20, 45, 30)),
			];

			extendedMaxY = @[
				MEDBox(CGRectMake(10, 10, 20, 15)),
				MEDBox(CGRectMake(10, 20, 30, 35)),
				MEDBox(CGRectMake(25, 15, 45, 30)),
			];

			if (leadingEdge == CGRectMinXEdge) {
				extendedLeading = extendedMinX;
				extendedTrailing = extendedMaxX;
			} else {
				extendedLeading = extendedMaxX;
				extendedTrailing = extendedMinX;
			}
		});

		it(@"should extend left side", ^{
			expect([[signal extendAttribute:NSLayoutAttributeLeft byAmount:value] array]).to.equal(extendedMinX);
		});

		it(@"should extend right side", ^{
			expect([[signal extendAttribute:NSLayoutAttributeRight byAmount:value] array]).to.equal(extendedMaxX);
		});

		it(@"should extend leading side", ^{
			expect([[signal extendAttribute:NSLayoutAttributeLeading byAmount:value] array]).to.equal(extendedLeading);
		});

		it(@"should extend trailing side", ^{
			expect([[signal extendAttribute:NSLayoutAttributeTrailing byAmount:value] array]).to.equal(extendedTrailing);
		});

		it(@"should extend top", ^{
			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				expect([[signal extendAttribute:NSLayoutAttributeTop byAmount:value] array]).to.equal(extendedMinY);
			#elif TARGET_OS_MAC
				expect([[signal extendAttribute:NSLayoutAttributeTop byAmount:value] array]).to.equal(extendedMaxY);
			#endif
		});

		it(@"should extend bottom", ^{
			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				expect([[signal extendAttribute:NSLayoutAttributeBottom byAmount:value] array]).to.equal(extendedMaxY);
			#elif TARGET_OS_MAC
				expect([[signal extendAttribute:NSLayoutAttributeBottom byAmount:value] array]).to.equal(extendedMinY);
			#endif
		});

		it(@"should extend width", ^{
			NSArray *expected = @[
				MEDBox(CGRectMake(12.5, 10, 15, 20)),
				MEDBox(CGRectMake(12.5, 20, 25, 40)),
				MEDBox(CGRectMake(27.5, 15, 40, 35)),
			];

			expect([[signal extendAttribute:NSLayoutAttributeWidth byAmount:value] array]).to.equal(expected);
		});

		it(@"should extend height", ^{
			NSArray *expected = @[
				MEDBox(CGRectMake(10, 12.5, 20, 15)),
				MEDBox(CGRectMake(10, 22.5, 30, 35)),
				MEDBox(CGRectMake(25, 17.5, 45, 30)),
			];

			expect([[signal extendAttribute:NSLayoutAttributeHeight byAmount:value] array]).to.equal(expected);
		});
	});

	it(@"should divide into two rects", ^{
		RACTupleUnpack(RACSignal *slices, RACSignal *remainders) = [signal divideWithAmount:[RACSignal return:@15] fromEdge:NSLayoutAttributeLeft];

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

		expect([slices array]).to.equal(expectedSlices);
		expect([remainders array]).to.equal(expectedRemainders);
	});

	it(@"should divide into two rects with padding", ^{
		RACTupleUnpack(RACSignal *slices, RACSignal *remainders) = [signal divideWithAmount:[RACSignal return:@15] padding:[RACSignal return:@3] fromEdge:NSLayoutAttributeLeft];

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

		expect([slices array]).to.equal(expectedSlices);
		expect([remainders array]).to.equal(expectedRemainders);
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

	describe(@"aligning attributes", ^{
		__block RACSignal *value;
		
		__block NSArray *alignedMinX;
		__block NSArray *alignedMaxX;
		__block NSArray *alignedMinY;
		__block NSArray *alignedMaxY;

		__block NSArray *alignedLeading;
		__block NSArray *alignedTrailing;
		
		beforeEach(^{
			value = [RACSignal return:@3];

			alignedMinX = @[
				MEDBox(CGRectMake(3, 10, 20, 20)),
				MEDBox(CGRectMake(3, 20, 30, 40)),
				MEDBox(CGRectMake(3, 15, 45, 35)),
			];

			alignedMaxX = @[
				MEDBox(CGRectMake(-17, 10, 20, 20)),
				MEDBox(CGRectMake(-27, 20, 30, 40)),
				MEDBox(CGRectMake(-42, 15, 45, 35)),
			];

			alignedMinY = @[
				MEDBox(CGRectMake(10, 3, 20, 20)),
				MEDBox(CGRectMake(10, 3, 30, 40)),
				MEDBox(CGRectMake(25, 3, 45, 35)),
			];

			alignedMaxY = @[
				MEDBox(CGRectMake(10, -17, 20, 20)),
				MEDBox(CGRectMake(10, -37, 30, 40)),
				MEDBox(CGRectMake(25, -32, 45, 35)),
			];

			if (leadingEdge == CGRectMinXEdge) {
				alignedLeading = alignedMinX;
				alignedTrailing = alignedMaxX;
			} else {
				alignedLeading = alignedMaxX;
				alignedTrailing = alignedMinX;
			}
		});

		it(@"should align left side to a specified value", ^{
			expect([[signal alignAttribute:NSLayoutAttributeLeft to:value] array]).to.equal(alignedMinX);
			expect([[signal alignLeft:value] array]).to.equal(alignedMinX);
		});

		it(@"should align right side to a specified value", ^{
			expect([[signal alignAttribute:NSLayoutAttributeRight to:value] array]).to.equal(alignedMaxX);
			expect([[signal alignRight:value] array]).to.equal(alignedMaxX);
		});

		it(@"should align leading side to a specified value", ^{
			expect([[signal alignAttribute:NSLayoutAttributeLeading to:value] array]).to.equal(alignedLeading);
			expect([[signal alignLeading:value] array]).to.equal(alignedLeading);
		});

		it(@"should align trailing side to a specified value", ^{
			expect([[signal alignAttribute:NSLayoutAttributeTrailing to:value] array]).to.equal(alignedTrailing);
			expect([[signal alignTrailing:value] array]).to.equal(alignedTrailing);
		});

		it(@"should align top to a specified value", ^{
			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				expect([[signal alignAttribute:NSLayoutAttributeTop to:value] array]).to.equal(alignedMinY);
				expect([[signal alignTop:value] array]).to.equal(alignedMinY);
			#elif TARGET_OS_MAC
				expect([[signal alignAttribute:NSLayoutAttributeTop to:value] array]).to.equal(alignedMaxY);
				expect([[signal alignTop:value] array]).to.equal(alignedMaxY);
			#endif
		});

		it(@"should align bottom to a specified value", ^{
			#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
				expect([[signal alignAttribute:NSLayoutAttributeBottom to:value] array]).to.equal(alignedMaxY);
				expect([[signal alignBottom:value] array]).to.equal(alignedMaxY);
			#elif TARGET_OS_MAC
				expect([[signal alignAttribute:NSLayoutAttributeBottom to:value] array]).to.equal(alignedMinY);
				expect([[signal alignBottom:value] array]).to.equal(alignedMinY);
			#endif
		});

		it(@"should align width to a specified value", ^{
			NSArray *expected = @[
				MEDBox(CGRectMake(10, 10, 3, 20)),
				MEDBox(CGRectMake(10, 20, 3, 40)),
				MEDBox(CGRectMake(25, 15, 3, 35)),
			];

			expect([[signal alignAttribute:NSLayoutAttributeWidth to:value] array]).to.equal(expected);
			expect([[signal alignWidth:value] array]).to.equal(expected);
		});

		it(@"should align height to a specified value", ^{
			NSArray *expected = @[
				MEDBox(CGRectMake(10, 10, 20, 3)),
				MEDBox(CGRectMake(10, 20, 30, 3)),
				MEDBox(CGRectMake(25, 15, 45, 3)),
			];

			expect([[signal alignAttribute:NSLayoutAttributeHeight to:value] array]).to.equal(expected);
			expect([[signal alignHeight:value] array]).to.equal(expected);
		});

		it(@"should align center X to a specified value", ^{
			NSArray *expected = @[
				MEDBox(CGRectMake(-7, 10, 20, 20)),
				MEDBox(CGRectMake(-12, 20, 30, 40)),
				MEDBox(CGRectMake(-19.5, 15, 45, 35)),
			];

			expect([[signal alignAttribute:NSLayoutAttributeCenterX to:value] array]).to.equal(expected);
			expect([[signal alignCenterX:value] array]).to.equal(expected);
		});

		it(@"should align center Y to a specified value", ^{
			NSArray *expected = @[
				MEDBox(CGRectMake(10, -7, 20, 20)),
				MEDBox(CGRectMake(10, -17, 30, 40)),
				MEDBox(CGRectMake(25, -14.5, 45, 35)),
			];

			expect([[signal alignAttribute:NSLayoutAttributeCenterY to:value] array]).to.equal(expected);
			expect([[signal alignCenterY:value] array]).to.equal(expected);
		});

		it(@"should align center point to a specified value", ^{
			CGPoint center = CGPointMake(5, 10);
			RACSignal *aligned = [signal alignCenter:[RACSignal return:MEDBox(center)]];

			NSArray *expected = @[
				MEDBox(CGRectMake(-5, 0, 20, 20)),
				MEDBox(CGRectMake(-10, -10, 30, 40)),
				MEDBox(CGRectMake(-17.5, -7.5, 45, 35)),
			];

			expect([aligned array]).to.equal(expected);
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

				NSArray *expected = @[
					MEDBox(CGRectMake(10, 22, 20, 20)),
					MEDBox(CGRectMake(10, 2, 30, 40)),
					MEDBox(CGRectMake(25, 7, 45, 35)),
				];

				expect([aligned array]).to.equal(expected);
			});
		#elif TARGET_OS_MAC
			it(@"should align to a baseline", ^{
				RACSignal *reference = [RACSignal return:MEDBox(CGRectMake(0, 30, 0, 15))];
				RACSignal *aligned = [signal alignBaseline:baseline1 toBaseline:baseline2 ofRect:reference];

				NSArray *expected = @[
					MEDBox(CGRectMake(10, 33, 20, 20)),
					MEDBox(CGRectMake(10, 33, 30, 40)),
					MEDBox(CGRectMake(25, 33, 45, 35)),
				];

				expect([aligned array]).to.equal(expected);
			});
		#endif
	});

	it(@"should replace size", ^{
		RACSignal *replacement = [RACSignal return:MEDBox(CGSizeMake(15, 25))];
		RACSignal *result = [signal replaceSize:replacement];

		NSArray *expected = @[
			MEDBox(CGRectMake(10, 10, 15, 25)),
			MEDBox(CGRectMake(10, 20, 15, 25)),
			MEDBox(CGRectMake(25, 15, 15, 25)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should replace width", ^{
		RACSignal *replacement = [RACSignal return:@5];
		RACSignal *result = [signal replaceWidth:replacement];

		NSArray *expected = @[
			MEDBox(CGRectMake(10, 10, 5, 20)),
			MEDBox(CGRectMake(10, 20, 5, 40)),
			MEDBox(CGRectMake(25, 15, 5, 35)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should replace height", ^{
		RACSignal *replacement = [RACSignal return:@15];
		RACSignal *result = [signal replaceHeight:replacement];

		NSArray *expected = @[
			MEDBox(CGRectMake(10, 10, 20, 15)),
			MEDBox(CGRectMake(10, 20, 30, 15)),
			MEDBox(CGRectMake(25, 15, 45, 15)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should replace origin", ^{
		RACSignal *replacement = [RACSignal return:MEDBox(CGPointMake(15, 25))];
		RACSignal *result = [signal replaceOrigin:replacement];

		NSArray *expected = @[
			MEDBox(CGRectMake(15, 25, 20, 20)),
			MEDBox(CGRectMake(15, 25, 30, 40)),
			MEDBox(CGRectMake(15, 25, 45, 35)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should be negated", ^{
		RACSignal *result = [signal negate];

		NSArray *expected = @[
			MEDBox(CGRectStandardize(CGRectMake(-10, -10, -20, -20))),
			MEDBox(CGRectStandardize(CGRectMake(-10, -20, -30, -40))),
			MEDBox(CGRectStandardize(CGRectMake(-25, -15, -45, -35))),
		];

		expect([result array]).to.equal(expected);
	});
});

describe(@"signal of CGSizes", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = [sizes.rac_signal subscribeOn:[RACScheduler scheduler]];
	});

	it(@"should map to widths", ^{
		expect([signal.width array]).to.equal(widths);
	});

	it(@"should map to heights", ^{
		expect([signal.height array]).to.equal(heights);
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

	it(@"should replace width", ^{
		RACSignal *replacement = [RACSignal return:@5];
		RACSignal *result = [signal replaceWidth:replacement];

		NSArray *expected = @[
			MEDBox(CGSizeMake(5, 20)),
			MEDBox(CGSizeMake(5, 40)),
			MEDBox(CGSizeMake(5, 35)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should replace height", ^{
		RACSignal *replacement = [RACSignal return:@15];
		RACSignal *result = [signal replaceHeight:replacement];

		NSArray *expected = @[
			MEDBox(CGSizeMake(20, 15)),
			MEDBox(CGSizeMake(30, 15)),
			MEDBox(CGSizeMake(45, 15)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should be negated", ^{
		RACSignal *result = [signal negate];

		NSArray *expected = @[
			MEDBox(CGSizeMake(-20, -20)),
			MEDBox(CGSizeMake(-30, -40)),
			MEDBox(CGSizeMake(-45, -35)),
		];

		expect([result array]).to.equal(expected);
	});
});

describe(@"signal of CGPoints", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = [points.rac_signal subscribeOn:[RACScheduler scheduler]];
	});

	it(@"should map to minXs", ^{
		expect([signal.x array]).to.equal(minXs);
	});

	it(@"should map to minYs", ^{
		expect([signal.y array]).to.equal(minYs);
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

	it(@"should replace X", ^{
		RACSignal *replacement = [RACSignal return:@5];
		RACSignal *result = [signal replaceX:replacement];

		NSArray *expected = @[
			MEDBox(CGPointMake(5, 10)),
			MEDBox(CGPointMake(5, 20)),
			MEDBox(CGPointMake(5, 15)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should replace Y", ^{
		RACSignal *replacement = [RACSignal return:@5];
		RACSignal *result = [signal replaceY:replacement];

		NSArray *expected = @[
			MEDBox(CGPointMake(10, 5)),
			MEDBox(CGPointMake(10, 5)),
			MEDBox(CGPointMake(25, 5)),
		];

		expect([result array]).to.equal(expected);
	});

	it(@"should be negated", ^{
		RACSignal *result = [signal negate];

		NSArray *expected = @[
			MEDBox(CGPointMake(-10, -10)),
			MEDBox(CGPointMake(-10, -20)),
			MEDBox(CGPointMake(-25, -15)),
		];

		expect([result array]).to.equal(expected);
	});
});

describe(@"signal of CGFloats", ^{
	__block RACSignal *signal;

	beforeEach(^{
		signal = [widths.rac_signal subscribeOn:[RACScheduler scheduler]];
	});

	it(@"should be negated", ^{
		RACSignal *result = [signal negate];

		NSArray *expected = @[
			@(-20),
			@(-30),
			@(-45),
		];

		expect([result array]).to.equal(expected);
	});
});

it(@"should return maximums and minimums", ^{
	RACSubject *firstSubject = [RACSubject subject];
	RACSubject *secondSubject = [RACSubject subject];

	NSMutableArray *receivedMaximums = [NSMutableArray array];
	[[RACSignal max:@[ firstSubject, secondSubject ]] subscribeNext:^(NSNumber *n) {
		[receivedMaximums addObject:n];
	}];

	NSMutableArray *receivedMinimums = [NSMutableArray array];
	[[RACSignal min:@[ firstSubject, secondSubject ]] subscribeNext:^(NSNumber *n) {
		[receivedMinimums addObject:n];
	}];

	NSMutableArray *minimums = [NSMutableArray array];
	NSMutableArray *maximums = [NSMutableArray array];

	[firstSubject sendNext:@20];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[secondSubject sendNext:@30];
	[minimums addObject:@20];
	[maximums addObject:@30];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[firstSubject sendNext:@15];
	[minimums addObject:@15];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[secondSubject sendNext:@45];
	[maximums addObject:@45];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[firstSubject sendNext:@40];
	[minimums addObject:@40];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[secondSubject sendNext:@30];
	[minimums addObject:@30];
	[maximums addObject:@40];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[firstSubject sendNext:@35];
	[maximums addObject:@35];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);

	[secondSubject sendNext:@50];
	[minimums addObject:@35];
	[maximums addObject:@50];

	expect(receivedMinimums).to.equal(minimums);
	expect(receivedMaximums).to.equal(maximums);
});

describe(@"mathematical operators", ^{
	__block RACSignal *numberA;
	__block RACSignal *numberB;
	__block NSArray *threeNumbers;

	__block RACSignal *pointA;
	__block RACSignal *pointB;
	__block NSArray *threePoints;

	__block RACSignal *sizeA;
	__block RACSignal *sizeB;
	__block NSArray *threeSizes;

	beforeEach(^{
		numberA = [RACSignal return:@5];
		numberB = [RACSignal return:@2];
		threeNumbers = @[ numberA, numberB, [RACSignal return:@3] ];

		pointA = [RACSignal return:MEDBox(CGPointMake(5, 10))];
		pointB = [RACSignal return:MEDBox(CGPointMake(1, 2))];
		threePoints = @[ pointA, pointB, [RACSignal return:MEDBox(CGPointMake(2, 1))] ];

		sizeA = [RACSignal return:MEDBox(CGSizeMake(5, 10))];
		sizeB = [RACSignal return:MEDBox(CGSizeMake(1, 2))];
		threeSizes = @[ sizeA, sizeB, [RACSignal return:MEDBox(CGSizeMake(2, 1))] ];
	});

	describe(@"+add:", ^{
		it(@"should add three numbers", ^{
			expect([[RACSignal add:threeNumbers] array]).to.equal(@[ @10 ]);
		});

		it(@"should add three points", ^{
			CGPoint expected = CGPointMake(8, 13);
			expect([[RACSignal add:threePoints] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should add three sizes", ^{
			CGSize expected = CGSizeMake(8, 13);
			expect([[RACSignal add:threeSizes] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"-plus:", ^{
		it(@"should add two numbers", ^{
			expect([[numberA plus:numberB] array]).to.equal(@[ @7 ]);
		});

		it(@"should add two points", ^{
			CGPoint expected = CGPointMake(6, 12);
			expect([[pointA plus:pointB] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should add two sizes", ^{
			CGSize expected = CGSizeMake(6, 12);
			expect([[sizeA plus:sizeB] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"+subtract:", ^{
		it(@"should subtract three numbers", ^{
			expect([[RACSignal subtract:threeNumbers] array]).to.equal(@[ @0 ]);
		});

		it(@"should subtract three points", ^{
			CGPoint expected = CGPointMake(2, 7);
			expect([[RACSignal subtract:threePoints] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should subtract three sizes", ^{
			CGSize expected = CGSizeMake(2, 7);
			expect([[RACSignal subtract:threeSizes] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"-minus:", ^{
		it(@"should subtract two numbers", ^{
			expect([[numberA minus:numberB] array]).to.equal(@[ @3 ]);
		});

		it(@"should subtract two points", ^{
			CGPoint expected = CGPointMake(4, 8);
			expect([[pointA minus:pointB] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should subtract two sizes", ^{
			CGSize expected = CGSizeMake(4, 8);
			expect([[sizeA minus:sizeB] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"+multiply:", ^{
		it(@"should multiply three numbers", ^{
			expect([[RACSignal multiply:threeNumbers] array]).to.equal(@[ @30 ]);
		});

		it(@"should multiply three points", ^{
			CGPoint expected = CGPointMake(10, 20);
			expect([[RACSignal multiply:threePoints] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should multiply three sizes", ^{
			CGSize expected = CGSizeMake(10, 20);
			expect([[RACSignal multiply:threeSizes] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"-multipliedBy:", ^{
		it(@"should multiply two numbers", ^{
			expect([[numberA multipliedBy:numberB] array]).to.equal(@[ @10 ]);
		});

		it(@"should multiply two points", ^{
			CGPoint expected = CGPointMake(5, 20);
			expect([[pointA multipliedBy:pointB] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should multiply two sizes", ^{
			CGSize expected = CGSizeMake(5, 20);
			expect([[sizeA multipliedBy:sizeB] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"+divide:", ^{
		it(@"should divide three numbers", ^{
			CGFloat result = [[[RACSignal divide:threeNumbers] first] doubleValue];
			expect(result).to.beCloseTo(5.0 / 2 / 3);
		});

		it(@"should divide three points", ^{
			CGPoint expected = CGPointMake(2.5, 5);
			expect([[RACSignal divide:threePoints] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should divide three sizes", ^{
			CGSize expected = CGSizeMake(2.5, 5);
			expect([[RACSignal divide:threeSizes] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});

	describe(@"-dividedBy:", ^{
		it(@"should divide two numbers", ^{
			expect([[numberA dividedBy:numberB] array]).to.equal(@[ @2.5 ]);
		});

		it(@"should divide two points", ^{
			CGPoint expected = CGPointMake(5, 5);
			expect([[pointA dividedBy:pointB] array]).to.equal(@[ MEDBox(expected) ]);
		});

		it(@"should divide two sizes", ^{
			CGSize expected = CGSizeMake(5, 5);
			expect([[sizeA dividedBy:sizeB] array]).to.equal(@[ MEDBox(expected) ]);
		});
	});
});

describe(@"-floor", ^{
	it(@"should floor CGFloats", ^{
		NSArray *values = @[ @2, @3.5, @4.75, @5.2 ];
		RACSignal *floored = values.rac_signal.floor;

		NSArray *expected = @[ @2, @3, @4, @5 ];
		expect([floored array]).to.equal(expected);
	});

	it(@"should floor CGPoints", ^{
		NSArray *values = @[
			MEDBox(CGPointMake(1, 1)),
			MEDBox(CGPointMake(2.2, 3.8)),
			MEDBox(CGPointMake(4.5, 5)),
		];

		RACSignal *floored = values.rac_signal.floor;
		NSArray *expected = [[values.rac_signal
			map:^(NSValue *value) {
				return MEDBox(MEDPointFloor(value.med_pointValue));
			}]
			array];

		expect([floored array]).to.equal(expected);
	});

	it(@"should floor CGSizes", ^{
		NSArray *values = @[
			MEDBox(CGSizeMake(1, 1)),
			MEDBox(CGSizeMake(2.2, 3.8)),
			MEDBox(CGSizeMake(4.5, 5)),
		];

		RACSignal *floored = values.rac_signal.floor;

		NSArray *expected = @[
			MEDBox(CGSizeMake(1, 1)),
			MEDBox(CGSizeMake(2, 3)),
			MEDBox(CGSizeMake(4, 5)),
		];

		expect([floored array]).to.equal(expected);
	});

	it(@"should floor CGRects", ^{
		NSArray *values = @[
			MEDBox(CGRectMake(1, 1, 2, 3)),
			MEDBox(CGRectMake(2.2, 3.8, 4.5, 5)),
			MEDBox(CGRectMake(6, 7, 8.1, 9.3)),
		];

		RACSignal *floored = values.rac_signal.floor;
		NSArray *expected = [[values.rac_signal
			map:^(NSValue *value) {
				return MEDBox(MEDRectFloor(value.med_rectValue));
			}]
			array];

		expect([floored array]).to.equal(expected);
	});
});

describe(@"-ceil", ^{
	it(@"should ceil CGFloats", ^{
		NSArray *values = @[ @2, @3.5, @4.75, @5.2 ];
		RACSignal *ceiled = values.rac_signal.ceil;

		NSArray *expected = @[ @2, @4, @5, @6 ];
		expect([ceiled array]).to.equal(expected);
	});

	it(@"should ceil CGPoints", ^{
		NSArray *values = @[
			MEDBox(CGPointMake(1, 1)),
			MEDBox(CGPointMake(2.2, 3.8)),
			MEDBox(CGPointMake(4.5, 5)),
		];

		RACSignal *ceiled = values.rac_signal.ceil;

		NSArray *expected = @[
			MEDBox(CGPointMake(1, 1)),
			MEDBox(CGPointMake(2, 3)),
			MEDBox(CGPointMake(4, 5)),
		];

		expect([ceiled array]).to.equal(expected);
	});

	it(@"should ceil CGSizes", ^{
		NSArray *values = @[
			MEDBox(CGSizeMake(1, 1)),
			MEDBox(CGSizeMake(2.2, 3.8)),
			MEDBox(CGSizeMake(4.5, 5)),
		];

		RACSignal *ceiled = values.rac_signal.ceil;

		NSArray *expected = @[
			MEDBox(CGSizeMake(1, 1)),
			MEDBox(CGSizeMake(3, 4)),
			MEDBox(CGSizeMake(5, 5)),
		];

		expect([ceiled array]).to.equal(expected);
	});

	it(@"should ceil CGRects", ^{
		NSArray *values = @[
			MEDBox(CGRectMake(1, 1, 2, 3)),
			MEDBox(CGRectMake(2.2, 3.8, 4.5, 5)),
			MEDBox(CGRectMake(6, 7, 8.1, 9.3)),
		];

		RACSignal *ceiled = values.rac_signal.ceil;
		NSArray *expected = [[values.rac_signal
			map:^(NSValue *value) {
				return MEDBox(CGRectIntegral(value.med_rectValue));
			}]
			array];

		expect([ceiled array]).to.equal(expected);
	});
});

describe(@"-offsetByAmount:towardEdge:", ^{
	__block RACSignal *rectSignal;
	__block RACSignal *pointSignal;
	__block RACSignal *amount;

	__block RACSignal *offsetMinX;
	__block RACSignal *offsetMinY;
	__block RACSignal *offsetMaxX;
	__block RACSignal *offsetMaxY;
	__block RACSignal *offsetLeading;
	__block RACSignal *offsetTrailing;

	beforeEach(^{
		amount = [RACSignal return:@8];
		
		pointSignal = [points.rac_signal subscribeOn:[RACScheduler scheduler]];
		rectSignal = [RACSignal rectsWithOrigin:pointSignal size:[RACSignal zeroSize]];

		offsetMinX = @[
			MEDBox(CGRectMake(2, 10, 0, 0)),
			MEDBox(CGRectMake(2, 20, 0, 0)),
			MEDBox(CGRectMake(17, 15, 0, 0)),
		].rac_signal;

		offsetMinY = @[
			MEDBox(CGRectMake(10, 2, 0, 0)),
			MEDBox(CGRectMake(10, 12, 0, 0)),
			MEDBox(CGRectMake(25, 7, 0, 0)),
		].rac_signal;

		offsetMaxX = @[
			MEDBox(CGRectMake(18, 10, 0, 0)),
			MEDBox(CGRectMake(18, 20, 0, 0)),
			MEDBox(CGRectMake(33, 15, 0, 0)),
		].rac_signal;

		offsetMaxY = @[
			MEDBox(CGRectMake(10, 18, 0, 0)),
			MEDBox(CGRectMake(10, 28, 0, 0)),
			MEDBox(CGRectMake(25, 23, 0, 0)),
		].rac_signal;

		if (leadingEdge == CGRectMinXEdge) {
			offsetLeading = offsetMinX;
			offsetTrailing = offsetMaxX;
		} else {
			offsetLeading = offsetMaxX;
			offsetTrailing = offsetMinX;
		}
	});

	it(@"should offset left side by a specified amount", ^{
		expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeLeft] array]).to.equal([offsetMinX.origin array]);
		expect([[pointSignal moveLeft:amount] array]).to.equal([offsetMinX.origin array]);

		expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeLeft] array]).to.equal([offsetMinX array]);
		expect([[rectSignal moveLeft:amount] array]).to.equal([offsetMinX array]);
	});

	it(@"should offset right side by a specified amount", ^{
		expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeRight] array]).to.equal([offsetMaxX.origin array]);
		expect([[pointSignal moveRight:amount] array]).to.equal([offsetMaxX.origin array]);

		expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeRight] array]).to.equal([offsetMaxX array]);
		expect([[rectSignal moveRight:amount] array]).to.equal([offsetMaxX array]);
	});

	it(@"should offset leading side by a specified amount", ^{
		expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeLeading] array]).to.equal([offsetLeading.origin array]);
		expect([[pointSignal moveLeadingOutward:amount] array]).to.equal([offsetLeading.origin array]);

		expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeLeading] array]).to.equal([offsetLeading array]);
		expect([[rectSignal moveLeadingOutward:amount] array]).to.equal([offsetLeading array]);
	});

	it(@"should offset trailing side by a specified amount", ^{
		expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeTrailing] array]).to.equal([offsetTrailing.origin array]);
		expect([[pointSignal moveTrailingOutward:amount] array]).to.equal([offsetTrailing.origin array]);

		expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeTrailing] array]).to.equal([offsetTrailing array]);
		expect([[rectSignal moveTrailingOutward:amount] array]).to.equal([offsetTrailing array]);
	});

	it(@"should offset top side by a specified value", ^{
		#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
			expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeTop] array]).to.equal([offsetMinY.origin array]);
			expect([[pointSignal moveUp:amount] array]).to.equal([offsetMinY.origin array]);

			expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeTop] array]).to.equal([offsetMinY array]);
			expect([[rectSignal moveUp:amount] array]).to.equal([offsetMinY array]);
		#elif TARGET_OS_MAC
			expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeTop] array]).to.equal([offsetMaxY.origin array]);
			expect([[pointSignal moveUp:amount] array]).to.equal([offsetMaxY.origin array]);

			expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeTop] array]).to.equal([offsetMaxY array]);
			expect([[rectSignal moveUp:amount] array]).to.equal([offsetMaxY array]);
		#endif
	});

	it(@"should offset bottom side by a specified value", ^{
		#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
			expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeBottom] array]).to.equal([offsetMaxY.origin array]);
			expect([[pointSignal moveDown:amount] array]).to.equal([offsetMaxY.origin array]);

			expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeBottom] array]).to.equal([offsetMaxY array]);
			expect([[rectSignal moveDown:amount] array]).to.equal([offsetMaxY array]);
		#elif TARGET_OS_MAC
			expect([[pointSignal offsetByAmount:amount towardEdge:NSLayoutAttributeBottom] array]).to.equal([offsetMinY.origin array]);
			expect([[pointSignal moveDown:amount] array]).to.equal([offsetMinY.origin array]);

			expect([[rectSignal offsetByAmount:amount towardEdge:NSLayoutAttributeBottom] array]).to.equal([offsetMinY array]);
			expect([[rectSignal moveDown:amount] array]).to.equal([offsetMinY array]);
		#endif
	});
});

SpecEnd
