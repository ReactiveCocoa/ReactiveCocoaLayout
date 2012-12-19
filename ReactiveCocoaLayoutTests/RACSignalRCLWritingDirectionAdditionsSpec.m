//
//  RACSignalRCLWritingDirectionAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-18.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(RACSignalRCLWritingDirectionAdditionsSpec)

it(@"should immediately send the current leading edge", ^{
	NSNumber *edge = [RACSignal.leadingEdgeSignal first];
	expect(edge).notTo.beNil();
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMinYEdge);
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMaxYEdge);
});

it(@"should immediately send the current trailing edge", ^{
	NSNumber *edge = [RACSignal.trailingEdgeSignal first];
	expect(edge).notTo.beNil();
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMinYEdge);
	expect(edge.unsignedIntegerValue).notTo.equal(CGRectMaxYEdge);
});

SpecEnd
