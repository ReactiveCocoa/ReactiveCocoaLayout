//
//  RACSignalRCLAnimationAdditionsSpec.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-01-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

SpecBegin(RACSignalRCLAnimationAdditions)

__block RACSignal *baseSignal;

beforeEach(^{
	baseSignal = [RACSignal return:@0];
});

describe(@"RCLIsInAnimatedSignal()", ^{
	it(@"should be false outside of an animated signal", ^{
		expect(RCLIsInAnimatedSignal()).to.beFalsy();
	});

	it(@"should be true from nexts of -animate", ^{
		[[[[baseSignal animate]
			doNext:^(id x) {
				expect(x).to.equal(@0);
				expect(RCLIsInAnimatedSignal()).to.beTruthy();
			}]
			doCompleted:^{
				expect(RCLIsInAnimatedSignal()).to.beFalsy();
			}]
			toArray];
	});

	it(@"should be true from nexts of -animateWithDuration:", ^{
		[[[[baseSignal animateWithDuration:0.01]
			doNext:^(id x) {
				expect(x).to.equal(@0);
				expect(RCLIsInAnimatedSignal()).to.beTruthy();
			}]
			doCompleted:^{
				expect(RCLIsInAnimatedSignal()).to.beFalsy();
			}]
			toArray];
	});

	it(@"should be true from nexts of -animateWithDuration:curve:", ^{
		[[[[baseSignal animateWithDuration:0.01 curve:RCLAnimationCurveEaseOut]
			doNext:^(id x) {
				expect(x).to.equal(@0);
				expect(RCLIsInAnimatedSignal()).to.beTruthy();
			}]
			doCompleted:^{
				expect(RCLIsInAnimatedSignal()).to.beFalsy();
			}]
			toArray];
	});
});

describe(@"-doAnimationCompleted:", ^{
	it(@"should trigger when the animation completes", ^{
		__block BOOL animationCompleted = NO;
		__block BOOL signalCompleted = NO;

		[[[baseSignal
			animate]
			doAnimationCompleted:^(id x) {
				animationCompleted = YES;
			}]
			subscribeCompleted:^{
				signalCompleted = YES;
			}];

		expect(signalCompleted).to.beTruthy();
		expect(animationCompleted).to.beFalsy();
		expect(animationCompleted).will.beTruthy();
	});

	it(@"should behave like -doNext: outside of an animated signal", ^{
		__block BOOL animationCompleted = NO;
		__block BOOL signalCompleted = NO;

		[[baseSignal
			doAnimationCompleted:^(id x) {
				expect(x).to.equal(@0);
				animationCompleted = YES;
			}]
			subscribeNext:^(id x) {
				expect(x).to.equal(@0);
				expect(animationCompleted).to.beTruthy();
			} completed:^{
				signalCompleted = YES;
			}];

		expect(animationCompleted).to.beTruthy();
		expect(signalCompleted).to.beTruthy();
	});
});

describe(@"-completeWithAnimation", ^{
	it(@"should complete only after the signal completes and all animations complete", ^{
		RACSubject *subject = [RACSubject subject];
		RACSignal *animated = [[subject animateWithDuration:0.1] completeWithAnimation];
		__block BOOL completed = NO;
		[animated subscribeCompleted:^{
			completed = YES;
		}];

		expect(completed).to.beFalsy();

		[subject sendNext:@1];
		expect(completed).to.beFalsy();

		[subject sendCompleted];
		// The underlying signal has completed but the animation hasn't yet.
		expect(completed).to.beFalsy();
		expect(completed).will.beTruthy();
	});
});

SpecEnd
