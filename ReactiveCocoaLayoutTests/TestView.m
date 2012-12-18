//
//  TestView.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-17.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "TestView.h"

@interface TestView ()

@property (nonatomic, assign) CGSize size;

@end

@implementation TestView

#pragma mark Test API

- (void)invalidateAndSetIntrinsicContentSize:(CGSize)size {
	self.size = size;
	[self invalidateIntrinsicContentSize];
}

#pragma mark Auto Layout

- (CGSize)intrinsicContentSize {
	return self.size;
}

@end
