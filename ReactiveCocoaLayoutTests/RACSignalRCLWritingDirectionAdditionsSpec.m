//
//  RACSignalRCLWritingDirectionAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-18.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(RACSignalRCLWritingDirectionAdditionsSpec)

it(@"should immediately send the current leading edge", ^{
	__block NSNumber *edge = nil;

	[RACSignal.leadingEdgeSignal subscribeNext:^(NSNumber *x) {
		edge = x;
	}];

	expect(edge).notTo.beNil();
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMinYEdge);
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMaxYEdge);
});

it(@"should immediately send the current trailing edge", ^{
	__block NSNumber *edge = nil;

	[RACSignal.trailingEdgeSignal subscribeNext:^(NSNumber *x) {
		edge = x;
	}];

	expect(edge).notTo.beNil();
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMinYEdge);
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMaxYEdge);
});

SpecEnd
