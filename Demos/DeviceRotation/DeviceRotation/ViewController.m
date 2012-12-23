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
@property (nonatomic, strong) UITextField *nameTextField;

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

	self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.nameLabel.font = [UIFont systemFontOfSize:30];

	self.nameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
	self.nameTextField.text = @"Some sample text";
	self.nameTextField.backgroundColor = UIColor.whiteColor;
	self.nameTextField.borderStyle = UITextBorderStyleRoundedRect;

	[self.view addSubview:self.nameLabel];
	[self.view addSubview:self.nameTextField];

	RACSignal *insetRect = [self.view.rcl_boundsSignal insetWidth:[RACSignal return:@16] height:[RACSignal return:@24]];

	RAC(self.nameLabel.text) = [self.rotationSignal map:^(NSNumber *orientation) {
		return (UIInterfaceOrientationIsPortrait(orientation.integerValue) ? NSLocalizedString(@"Portrait!", @"") : NSLocalizedString(@"Landscape awww yeaahhh", @""));
	}];

	RACTupleUnpack(RACSignal *labelRect, RACSignal *textFieldRect) = [insetRect divideWithAmount:self.nameLabel.rcl_intrinsicContentSizeSignal.width padding:[RACSignal return:@8] fromEdge:CGRectMinXEdge];

	textFieldRect = [textFieldRect sliceWithAmount:[RACSignal return:@28] fromEdge:CGRectMinYEdge];

	RAC(self.nameLabel.rcl_alignmentRect) = [[labelRect replaceSize:self.nameLabel.rcl_intrinsicContentSizeSignal]
		alignBaseline:self.nameLabel.rcl_baselineSignal toBaseline:self.nameTextField.rcl_baselineSignal ofRect:self.nameTextField.rcl_alignmentRectSignal];

	// Animate the initial appearance of the text view, but not any changes due
	// to rotation.
	RAC(self.nameTextField.rcl_alignmentRect) = [[[[textFieldRect animateWithDuration:1 curve:RCLAnimationCurveEaseOut] take:1] delay:1] sequenceNext:^{
		return textFieldRect;
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
