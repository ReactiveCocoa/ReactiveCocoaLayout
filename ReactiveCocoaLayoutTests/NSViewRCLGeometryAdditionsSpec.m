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

	describe(@"baseline", ^{
		__block CGFloat baseline;

		beforeEach(^{
			baseline = field.baselineOffsetFromBottom;
			expect(baseline).to.beGreaterThan(0);

			if ([field isFlipped]) {
				baseline = CGRectGetMaxY(field.bounds) - baseline;
			}
		});

		it(@"should send the baseline", ^{
			expect([[field.rcl_baselineSignal first] doubleValue]).to.equal(baseline);
		});
	});
});

SpecEnd
