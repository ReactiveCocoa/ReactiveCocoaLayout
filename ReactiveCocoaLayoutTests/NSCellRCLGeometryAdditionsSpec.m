//
//  NSCellRCLGeometryAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-31.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Archimedes/Archimedes.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoaLayout/ReactiveCocoaLayout.h>

QuickSpecBegin(NSCellRCLGeometryAdditions)

describe(@"NSTextFieldCell", ^{
	__block NSTextField *field;
	__block NSTextFieldCell *cell;

	beforeEach(^{
		field = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
		expect(field).notTo(beNil());

		cell = field.cell;
		expect(cell).notTo(beNil());
		expect(cell.controlView).to(equal(field));
	});

	it(@"should send values on -rcl_sizeSignal", ^{
		CGSize initialSize = cell.cellSize;

		__block NSValue *lastValue = nil;
		[cell.rcl_sizeSignal subscribeNext:^(NSValue *value) {
			expect(value).to(beAKindOf(NSValue.class));
			lastValue = value;
		}];

		expect(lastValue).notTo(beNil());
		expect(lastValue.med_sizeValue).to(equal(initialSize));

		cell.stringValue = @"foo\nbar";
		expect(cell.cellSize).notTo(equal(initialSize));
		expect(lastValue.med_sizeValue).to(equal(cell.cellSize));
	});

	it(@"should send values on -rcl_sizeSignalForBounds:", ^{
		RACSubject *boundsSubject = [RACSubject subject];

		__block NSValue *lastValue = nil;
		[[cell rcl_sizeSignalForBounds:boundsSubject] subscribeNext:^(NSValue *value) {
			expect(value).to(beAKindOf(NSValue.class));
			lastValue = value;
		}];

		// Shouldn't send anything until the first bounds value is received.
		expect(lastValue).to(beNil());

		CGRect bounds = CGRectMake(0, 0, 300, 300);
		CGSize size = [cell cellSizeForBounds:bounds];
		[boundsSubject sendNext:MEDBox(bounds)];

		expect(lastValue).notTo(beNil());
		expect(lastValue.med_sizeValue).to(equal(size));

		cell.stringValue = @"foo\nbar";
		expect([cell cellSizeForBounds:bounds]).notTo(equal(size));

		size = [cell cellSizeForBounds:bounds];
		expect(lastValue.med_sizeValue).to(equal(size));

		bounds = CGRectMake(0, 0, 2, 500);
		[boundsSubject sendNext:MEDBox(bounds)];
		expect([cell cellSizeForBounds:bounds]).notTo(equal(size));

		size = [cell cellSizeForBounds:bounds];
		expect(lastValue.med_sizeValue).to(equal(size));
	});
});

it(@"should complete rcl_sizeSignal upon deallocation", ^{
	__block BOOL completed = NO;

	@autoreleasepool {
		NSTextField *control __attribute__((objc_precise_lifetime)) = [[NSTextField alloc] initWithFrame:NSZeroRect];
		NSCell *cell __attribute__((objc_precise_lifetime)) = control.cell;

		[cell.rcl_sizeSignal subscribeCompleted:^{
			completed = YES;
		}];

		expect(completed).to(beFalsy());
	}

	expect(completed).to(beTruthy());
});

QuickSpecEnd
