//
//  NSControlRCLGeometryAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-30.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(NSControlRCLGeometryAdditions)

describe(@"NSTextField", ^{
	__block NSTextField *field;

	beforeEach(^{
		field = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
		expect(field).notTo.beNil();
	});

	it(@"should send the adjusted NSCell whenever the intrinsic content size changes", ^{
		__block NSCell *invalidatedCell = nil;
		[field.rcl_cellIntrinsicContentSizeInvalidatedSignal subscribeNext:^(NSCell *cell) {
			expect(cell).to.beKindOf(NSTextFieldCell.class);
			invalidatedCell = cell;
		}];

		[field.cell setStringValue:@"foo\nbar"];
		expect(invalidatedCell).to.equal(field.cell);
	});
});

describe(@"NSMatrix", ^{
	__block NSMatrix *matrix;
	__block NSCell *cell;

	beforeEach(^{
		matrix = [[NSMatrix alloc] initWithFrame:CGRectZero mode:NSListModeMatrix cellClass:NSTextFieldCell.class numberOfRows:2 numberOfColumns:2];
		expect(matrix).notTo.beNil();

		cell = matrix.cells[0];

		// This is apparently necessary for the controlView property to be
		// filled in.
		[matrix calcSize];

		expect(cell.controlView).to.equal(matrix);
	});

	it(@"should send the adjusted NSCell whenever the intrinsic content size changes", ^{
		NSMutableSet *invalidatedCells = [NSMutableSet set];
		[matrix.rcl_cellIntrinsicContentSizeInvalidatedSignal subscribeNext:^(NSCell *cell) {
			expect(cell).to.beKindOf(NSTextFieldCell.class);
			[invalidatedCells addObject:cell];
		}];
	
		cell.stringValue = @"foo\nbar";
		expect(invalidatedCells).to.contain(cell);
	});
});

SpecEnd
