//
//  RCLMacrosSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-11.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "TestView.h"

SpecBegin(RCLMacros)

__block TestView *view;

beforeEach(^{
	view = [[TestView alloc] initWithFrame:CGRectZero];
});

it(@"should bind constant values", ^{
	RCLFrame(view) = @{
		rcl_rect: MEDBox(CGRectMake(0, 0, 10, 20)),
		rcl_right: @15,
		rcl_height: @30,
	};

	expect(view.frame).to.equal(CGRectMake(5, 0, 10, 30));
});

SpecEnd
