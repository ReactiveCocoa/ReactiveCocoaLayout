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
@property (nonatomic, strong, readonly) id<RACSignal> rotationSignal;

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

	id<RCLSignal> insetBounds = [self.view.rcl_boundsSignal insetWidth:[RACSignal return:@16] height:[RACSignal return:@16]];

	self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.nameLabel];

	RAC(self.nameLabel.text) = [self.rotationSignal map:^(NSNumber *orientation) {
		return (UIInterfaceOrientationIsPortrait(orientation.integerValue) ? NSLocalizedString(@"Portrait!", @"") : NSLocalizedString(@"Landscape awww yeaahhh", @""));
	}];

	RAC(self.nameLabel.frame) = [RACSignal combineLatest:@[ insetBounds.origin, self.nameLabel.rcl_intrinsicContentSizeSignal ] reduce:^(NSValue *origin, NSValue *size) {
		CGRect frame = { .origin = origin.med_pointValue, .size = size.med_sizeValue };
		return MEDBox(frame);
	}];

	self.nameTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.nameTextView];

	RAC(self.nameTextView.frame) = [insetBounds divideWithAmount:self.nameLabel.rcl_frameSignal.size.width padding:[RACSignal return:@8] fromEdge:CGRectMinXEdge][1];
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
