//
//	ResizingWindowController.m
//	ResizingWindow
//
//	Created by Justin Spahr-Summers on 2012-12-12.
//	Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ResizingWindowController.h"

@interface ResizingWindowController ()

@property (nonatomic, strong, readonly) NSView *contentView;

@end

@implementation ResizingWindowController

#pragma mark Properties

- (NSView *)contentView {
	return self.window.contentView;
}

#pragma mark Lifecycle

- (id)init {
	return [self initWithWindowNibName:@"ResizingWindow"];
}

- (void)windowDidLoad {
	[super windowDidLoad];

	NSTextField *nameLabel = [self labelWithString:NSLocalizedString(@"Name", @"")];
	NSTextField *emailLabel = [self labelWithString:NSLocalizedString(@"Email Address", @"")];

	RACSignal *labelWidth = [RACSignal max:@[ nameLabel.rcl_boundsSignal.size.width, emailLabel.rcl_boundsSignal.size.width ]];

	NSTextField *nameField = [self textFieldWithString:@""];
	NSTextField *emailField = [self textFieldWithString:@""];

	RACTupleUnpack(RACSignal *nameRect, RACSignal *emailRect) = [[self.contentView.rcl_frameSignal
		insetWidth:[RACSignal return:@32] height:[RACSignal return:@16]]
		divideWithAmount:nameField.rcl_boundsSignal.size.height padding:[RACSignal return:@8] fromEdge:CGRectMaxYEdge];

	RACTuple *nameTuple = [nameRect divideWithAmount:labelWidth padding:[RACSignal return:@8] fromEdge:CGRectMinXEdge];
	RAC(nameLabel, frame) = nameTuple[0];
	RAC(nameField, frame) = nameTuple[1];

	RACTuple *emailTuple = [[emailRect
		sliceWithAmount:emailField.rcl_boundsSignal.size.height fromEdge:CGRectMaxYEdge]
		divideWithAmount:labelWidth padding:[RACSignal return:@8] fromEdge:CGRectMinXEdge];

	RAC(emailLabel, frame) = emailTuple[0];
	RAC(emailField, frame) = emailTuple[1];
}

#pragma mark View Creation

- (NSTextField *)labelWithString:(NSString *)string {
	NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
	label.editable = NO;
	label.selectable = NO;
	label.bezeled = NO;
	label.drawsBackground = NO;
	label.stringValue = string;
	[label sizeToFit];

	[self.contentView addSubview:label];
	return label;
}

- (NSTextField *)textFieldWithString:(NSString *)string {
	NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
	textField.stringValue = string;
	[textField sizeToFit];

	[self.contentView addSubview:textField];
	return textField;
}

@end
