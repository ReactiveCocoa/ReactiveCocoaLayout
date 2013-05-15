//
//  RCLMacrosSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-11.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "TestView.h"

static NSString * const MacroExamples = @"MacroExamples";

// Associated with a block that binds a dictionary of attributes to the desired
// view property. This block should be of type:
//
// void (^bind)(TestView *view, NSDictionary *attributes)
static NSString * const MacroBindingBlock = @"MacroBindingBlock";

// Associated with the name of the view property that is being bound.
static NSString * const MacroPropertyName = @"MacroPropertyName";

SharedExampleGroupsBegin(MacroExamples)

sharedExamplesFor(MacroExamples, ^(NSDictionary *bindingInfo) {
	CGSize intrinsicSize = CGSizeMake(10, 15);

	__block TestView *view;

	__block void (^bind)(NSDictionary *);
	__block CGRect (^getProperty)(void);

	__block CGRect rect;
	__block RACSubject *values;

	beforeEach(^{
		view = [[TestView alloc] initWithFrame:CGRectZero];
		[view invalidateAndSetIntrinsicContentSize:intrinsicSize];

		void (^innerBindingBlock)(TestView *, NSDictionary *) = bindingInfo[MacroBindingBlock];
		bind = [^(NSDictionary *bindings) {
			return innerBindingBlock(view, bindings);
		} copy];

		getProperty = [^{
			NSValue *boxedRect = [view valueForKey:bindingInfo[MacroPropertyName]];
			return boxedRect.med_rectValue;
		} copy];

		rect = (CGRect){ .size = intrinsicSize };
		values = [RACSubject subject];
	});

	it(@"should default to the view's intrinsic bounds", ^{
		bind(@{});

		CGRect rect = { .origin = CGPointZero, .size = intrinsicSize };
		expect(getProperty()).to.equal(rect);
	});

	describe(@"rcl_rect", ^{
		beforeEach(^{
			rect = CGRectMake(1, 7, 13, 21);
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_rect: MEDBox(rect)
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_rect: values
			});

			[values sendNext:MEDBox(rect)];
			expect(getProperty()).to.equal(rect);

			rect = CGRectMake(2, 3, 4, 5);

			[values sendNext:MEDBox(rect)];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_size", ^{
		beforeEach(^{
			rect.size = CGSizeMake(13, 21);
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_size: MEDBox(rect.size)
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_size: values
			});

			[values sendNext:MEDBox(rect.size)];
			expect(getProperty()).to.equal(rect);

			rect.size = CGSizeMake(4, 5);

			[values sendNext:MEDBox(rect.size)];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_origin", ^{
		beforeEach(^{
			rect = (CGRect){ .origin = CGPointMake(1, 3), .size = intrinsicSize };
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_origin: MEDBox(rect.origin)
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_origin: values
			});

			[values sendNext:MEDBox(rect.origin)];
			expect(getProperty()).to.equal(rect);

			rect.origin = CGPointMake(5, 7);

			[values sendNext:MEDBox(rect.origin)];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_width", ^{
		beforeEach(^{
			rect.size.width = 3;
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_width: @(rect.size.width)
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_width: values
			});

			[values sendNext:@(rect.size.width)];
			expect(getProperty()).to.equal(rect);

			rect.size.width = 7;

			[values sendNext:@(rect.size.width)];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_height", ^{
		beforeEach(^{
			rect.size.height = 3;
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_height: @(rect.size.height)
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_height: values
			});

			[values sendNext:@(rect.size.height)];
			expect(getProperty()).to.equal(rect);

			rect.size.height = 7;

			[values sendNext:@(rect.size.height)];
			expect(getProperty()).to.equal(rect);
		});
	});

	it(@"should bind constant values", ^{
		bind(@{
			rcl_rect: MEDBox(CGRectMake(0, 0, 10, 20)),
			rcl_right: @15,
			rcl_height: @30,
		});

		expect(getProperty()).to.equal(CGRectMake(5, 0, 10, 30));
	});
});

SharedExampleGroupsEnd

SpecBegin(RCLMacros)

itShouldBehaveLike(MacroExamples, @{
	MacroPropertyName: @"rcl_frame",
	MacroBindingBlock: ^(TestView *view, NSDictionary *bindings) {
		RCLFrame(view) = bindings;
	}
});

itShouldBehaveLike(MacroExamples, @{
	MacroPropertyName: @"rcl_alignmentRect",
	MacroBindingBlock: ^(TestView *view, NSDictionary *bindings) {
		RCLAlignment(view) = bindings;
	}
});

SpecEnd
