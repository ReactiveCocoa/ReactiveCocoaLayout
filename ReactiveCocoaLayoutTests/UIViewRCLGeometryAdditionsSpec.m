//
//  UIViewRCLGeometryAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ViewExamples.h"

SpecBegin(UIViewRCLGeometryAdditions)

itShouldBehaveLike(ViewExamples, nil);

describe(@"UILabel", ^{
	__block UILabel *label;

	beforeEach(^{
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
		expect(label).notTo.beNil();
	});

	describe(@"baseline", ^{
		__block CGFloat baseline;
		__block RACSignal *signal;

		beforeEach(^{
			UIView *baselineView = label.viewForBaselineLayout;
			expect(baselineView).notTo.beNil();
			
			CGRect baselineViewRect = [baselineView.superview convertRect:baselineView.frame toView:label];
			expect(baselineViewRect).notTo.equal(label.bounds);

			baseline = 20 - CGRectGetMaxY(baselineViewRect);
			expect(baseline).to.beGreaterThan(0);

			signal = [RACSignal return:MEDBox(CGRectMake(10, 20, 30, 40))];
		});

		it(@"should send the baseline", ^{
			expect([[label.rcl_baselineSignal first] doubleValue]).to.equal(baseline);
		});
	});
});

SpecEnd
