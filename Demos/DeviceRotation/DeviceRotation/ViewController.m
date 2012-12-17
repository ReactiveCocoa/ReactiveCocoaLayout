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

	@weakify(self);

	id<RCLSignal> insetBounds = [self.view.rcl_boundsSignal insetWidth:16 height:16];

	self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.nameLabel];

	RAC(self.nameLabel.text) = [self.rotationSignal map:^(NSNumber *orientation) {
		return (UIInterfaceOrientationIsPortrait(orientation.integerValue) ? NSLocalizedString(@"Portrait!", @"") : NSLocalizedString(@"Landscape awww yeaahhh", @""));
	}];

	RAC(self.nameLabel.frame) = [RACSignal combineLatest:@[ insetBounds, RACAbleWithStart(self.nameLabel.text).distinctUntilChanged ] reduce:^(NSValue *availableBounds, NSString *text) {
		@strongify(self);

		CGSize fittingSize = [self.nameLabel sizeThatFits:availableBounds.med_rectValue.size];
		CGPoint origin = availableBounds.med_rectValue.origin;
		return MEDBox(CGRectMake(origin.x, origin.y, fittingSize.width, fittingSize.height));
	}];

	self.nameTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.nameTextView];

	RAC(self.nameTextView.frame) = [RACSignal combineLatest:@[ insetBounds, self.nameLabel.rcl_frameSignal ] reduce:^(NSValue *availableBounds, NSValue *nameFrame) {
		CGRect frame = CGRectRemainder(availableBounds.med_rectValue, CGRectGetWidth(nameFrame.med_rectValue) + 8, CGRectMinXEdge);
		return MEDBox(frame);
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
