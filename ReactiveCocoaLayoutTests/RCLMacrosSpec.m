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

	describe(@"rcl_center", ^{
		__block NSValue * (^getCenter)(void);

		beforeEach(^{
			rect.origin = CGPointMake(2, 3);
			getCenter = ^{
				return MEDBox(CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)));
			};
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_center: getCenter()
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_center: values
			});

			[values sendNext:getCenter()];
			expect(getProperty()).to.equal(rect);

			rect.origin = CGPointMake(4, 5);

			[values sendNext:getCenter()];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_centerX", ^{
		__block NSNumber * (^getCenter)(void);

		beforeEach(^{
			rect.origin.x = 2;
			getCenter = ^{
				return @(CGRectGetMidX(rect));
			};
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_centerX: getCenter()
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_centerX: values
			});

			[values sendNext:getCenter()];
			expect(getProperty()).to.equal(rect);

			rect.origin.x = 4;

			[values sendNext:getCenter()];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_centerY", ^{
		__block NSNumber * (^getCenter)(void);

		beforeEach(^{
			rect.origin.y = 2;
			getCenter = ^{
				return @(CGRectGetMidY(rect));
			};
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_centerY: getCenter()
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_centerY: values
			});

			[values sendNext:getCenter()];
			expect(getProperty()).to.equal(rect);

			rect.origin.y = 4;

			[values sendNext:getCenter()];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_left", ^{
		beforeEach(^{
			rect.origin.x = 7;
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_left: @(rect.origin.x)
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_left: values
			});

			[values sendNext:@(rect.origin.x)];
			expect(getProperty()).to.equal(rect);

			rect.origin.x = 17;

			[values sendNext:@(rect.origin.x)];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_right", ^{
		__block NSNumber * (^getRight)(void);

		beforeEach(^{
			rect.origin.x = 7;
			getRight = ^{
				return @(CGRectGetMaxX(rect));
			};
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_right: getRight()
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_right: values
			});

			[values sendNext:getRight()];
			expect(getProperty()).to.equal(rect);

			rect.origin.x = 17;

			[values sendNext:getRight()];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_top", ^{
		__block NSNumber * (^getTop)(void);

		beforeEach(^{
			rect.origin.y = 7;
			getTop = ^{
				#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
					return @(CGRectGetMinY(rect));
				#elif TARGET_OS_MAC
					return @(CGRectGetMaxY(rect));
				#endif
			};
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_top: getTop()
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_top: values
			});

			[values sendNext:getTop()];
			expect(getProperty()).to.equal(rect);

			rect.origin.y = 17;

			[values sendNext:getTop()];
			expect(getProperty()).to.equal(rect);
		});
	});

	describe(@"rcl_bottom", ^{
		__block NSNumber * (^getBottom)(void);

		beforeEach(^{
			rect.origin.y = 7;
			getBottom = ^{
				#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
					return @(CGRectGetMaxY(rect));
				#elif TARGET_OS_MAC
					return @(CGRectGetMinY(rect));
				#endif
			};
		});

		it(@"should bind to a constant", ^{
			bind(@{
				rcl_bottom: getBottom()
			});

			expect(getProperty()).to.equal(rect);
		});

		it(@"should bind to a signal", ^{
			bind(@{
				rcl_bottom: values
			});

			[values sendNext:getBottom()];
			expect(getProperty()).to.equal(rect);

			rect.origin.y = 17;

			[values sendNext:getBottom()];
			expect(getProperty()).to.equal(rect);
		});
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
