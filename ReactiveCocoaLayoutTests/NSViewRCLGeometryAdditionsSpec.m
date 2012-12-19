//
//  NSViewRCLGeometryAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ViewExamples.h"

SpecBegin(NSViewRCLGeometryAdditions)

itShouldBehaveLike(ViewExamples, nil);

describe(@"NSTextField", ^{
	__block NSTextField *field;

	beforeEach(^{
		field = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
		expect(field).notTo.beNil();
	});

	describe(@"baseline adjustments", ^{
		__block CGFloat baseline;
		__block RACSignal *signal;

		beforeEach(^{
			baseline = field.baselineOffsetFromBottom;
			expect(baseline).to.beGreaterThan(0);

			signal = [RACSignal return:MEDBox(CGRectMake(10, 20, 30, 40))];
		});

		it(@"should inset by the baseline", ^{
			RACSignal *insetSignal = [field rcl_insetBaseline:signal];
			expect(insetSignal).notTo.beNil();

			NSValue *rect = [insetSignal first];
			expect(rect).notTo.beNil();

			CGRect expected = CGRectMake(10, 20 + baseline, 30, 40 - baseline);
			expect(rect.med_rectValue).to.equal(expected);
		});

		it(@"should outset by the baseline", ^{
			RACSignal *outsetSignal = [field rcl_outsetBaseline:signal];
			expect(outsetSignal).notTo.beNil();

			NSValue *rect = [outsetSignal first];
			expect(rect).notTo.beNil();

			CGRect expected = CGRectMake(10, 20 - baseline, 30, 40 + baseline);
			expect(rect.med_rectValue).to.equal(expected);
		});
	});
});

SpecEnd
