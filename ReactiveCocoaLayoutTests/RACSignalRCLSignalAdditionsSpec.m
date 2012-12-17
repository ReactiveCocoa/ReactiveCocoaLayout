//
//  RACSignalRCLSignalAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-15.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(RACSignalRCLSignalAdditions)

it(@"should conform to <RCLSignal>", ^{
	expect([RACSignal conformsToProtocol:@protocol(RACSignal)]).to.beTruthy();
});

SpecEnd
