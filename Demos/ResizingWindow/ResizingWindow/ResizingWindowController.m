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

@property (nonatomic, weak) NSTextField *emailLabel;
@property (nonatomic, weak) NSTextField *emailField;

@property (nonatomic, weak) NSTextField *nameLabel;
@property (nonatomic, weak) NSTextField *nameField;

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

	self.emailLabel = [self labelWithString:NSLocalizedString(@"Email Address", @"")];
	self.nameLabel = [self labelWithString:NSLocalizedString(@"Name", @"")];

	self.emailField = [self textFieldWithString:@""];
	self.nameField = [self textFieldWithString:@""];

	RACSignal *labelWidth = [RACSignal max:@[ self.nameLabel.rcl_intrinsicContentSizeSignal.width, self.emailLabel.rcl_intrinsicContentSizeSignal.width ]];
	RACSignal *padding = [RACSignal return:@8];

	RACTupleUnpack(RACSignal *emailRect, RACSignal *nameRect) = [[self.contentView.rcl_frameSignal
		insetWidth:[RACSignal return:@32] height:[RACSignal return:@16]]
		divideWithAmount:self.emailField.rcl_intrinsicContentSizeSignal.height padding:padding fromEdge:CGRectMaxYEdge];

	RACTupleUnpack(RACSignal *emailLabelRect, RACSignal *emailFieldRect) = [emailRect divideWithAmount:labelWidth padding:padding fromEdge:CGRectMinXEdge];

	RAC(self.emailField.rcl_alignmentRect) = emailFieldRect;
	RAC(self.emailLabel.rcl_alignmentRect) = [[emailLabelRect replaceSize:self.emailLabel.rcl_intrinsicContentSizeSignal]
		alignBaseline:self.emailLabel.rcl_baselineSignal toBaseline:self.emailField.rcl_baselineSignal ofRect:emailFieldRect];

	RACTupleUnpack(RACSignal *nameLabelRect, RACSignal *nameFieldRect) = [[nameRect
		sliceWithAmount:self.nameField.rcl_intrinsicContentSizeSignal.height fromEdge:CGRectMaxYEdge]
		divideWithAmount:labelWidth padding:padding fromEdge:CGRectMinXEdge];

	RAC(self.nameField.rcl_alignmentRect) = nameFieldRect;
	RAC(self.nameLabel.rcl_alignmentRect) = [[nameLabelRect replaceSize:self.nameLabel.rcl_intrinsicContentSizeSignal]
		alignBaseline:self.nameLabel.rcl_baselineSignal toBaseline:self.nameField.rcl_baselineSignal ofRect:nameFieldRect];
}

#pragma mark View Creation

- (NSTextField *)labelWithString:(NSString *)string {
	NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
	label.wantsLayer = YES;
	label.editable = NO;
	label.selectable = NO;
	label.bezeled = NO;
	label.drawsBackground = NO;
	label.stringValue = string;
	label.font = [NSFont systemFontOfSize:8];
	[label sizeToFit];

	// We don't actually use autoresizing to move these views, but rather to
	// keep them pinned in the absence of any movement.
	label.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;

	[self.contentView addSubview:label];
	return label;
}

- (NSTextField *)textFieldWithString:(NSString *)string {
	NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
	textField.wantsLayer = YES;
	textField.stringValue = string;
	[textField sizeToFit];

	// We don't actually use autoresizing to move these views, but rather to
	// keep them pinned in the absence of any movement.
	textField.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;

	[self.contentView addSubview:textField];
	return textField;
}

@end
