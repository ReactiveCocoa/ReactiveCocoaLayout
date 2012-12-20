//
//  ViewController.m
//  DeviceRotation
//
//  Created by Justin Spahr-Summers on 2012-12-13.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ViewController.h"
#import "EXTScope.h"

@interface ViewController () {
	RACSubject *_rotationSignal;
}

// Sends the new interface orientation every time a rotation occurs.
@property (nonatomic, strong, readonly) RACSignal *rotationSignal;

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UITextView *nameTextView;

@end

@implementation ViewController

#pragma mark Lifecycle

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle {
	self = [super initWithNibName:nibName bundle:bundle];
	if (self == nil) return nil;

	_rotationSignal = [RACSubject subject];

	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.backgroundColor = UIColor.lightGrayColor;

	RACSignal *insetBounds = [self.view.rcl_boundsSignal insetWidth:[RACSignal return:@16] height:[RACSignal return:@16]];

	self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.nameLabel];

	RAC(self.nameLabel.text) = [self.rotationSignal map:^(NSNumber *orientation) {
		return (UIInterfaceOrientationIsPortrait(orientation.integerValue) ? NSLocalizedString(@"Portrait!", @"") : NSLocalizedString(@"Landscape awww yeaahhh", @""));
	}];

	RAC(self.nameLabel.frame) = [RACSignal rectsWithOrigin:insetBounds.origin size:self.nameLabel.rcl_intrinsicContentSizeSignal];

	self.nameTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.nameTextView];

	RACSignal *textViewBounds = [insetBounds divideWithAmount:self.nameLabel.rcl_frameSignal.size.width padding:[RACSignal return:@8] fromEdge:CGRectMinXEdge][1];

	// Animate the initial appearance of the text view, but not any changes due
	// to rotation.
	RAC(self.nameTextView.frame) = [[[[textViewBounds animateWithDuration:1 curve:RCLAnimationCurveEaseOut] take:1] delay:1] sequenceNext:^{
		return textViewBounds;
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_rotationSignal sendNext:@(self.interfaceOrientation)];
}

#pragma mark Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
	[_rotationSignal sendNext:@(interfaceOrientation)];
}

@end
