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
	__block TestView *view;

	__block void (^bind)(NSDictionary *);
	__block CGRect (^getProperty)(void);

	beforeEach(^{
		view = [[TestView alloc] initWithFrame:CGRectZero];

		void (^innerBindingBlock)(TestView *, NSDictionary *) = bindingInfo[MacroBindingBlock];
		bind = [^(NSDictionary *bindings) {
			return innerBindingBlock(view, bindings);
		} copy];

		getProperty = [^{
			NSValue *boxedRect = [view valueForKey:bindingInfo[MacroPropertyName]];
			return boxedRect.med_rectValue;
		} copy];
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
