//
//	ResizingWindowController.m
//	ResizingWindow
//
//	Created by Justin Spahr-Summers on 2012-12-12.
//	Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ResizingWindowController.h"
#import "EXTScope.h"

@interface ResizingWindowController ()

@property (nonatomic, strong, readonly) NSView *contentView;

@property (nonatomic, assign) CGFloat labelWidth;

@property (nonatomic, weak) NSTextField *emailLabel;
@property (nonatomic, weak) NSTextField *emailField;
@property (nonatomic, copy) NSString *email;

@property (nonatomic, assign, getter = isConfirmEmailVisible) BOOL confirmEmailVisible;
@property (nonatomic, weak) NSTextField *confirmEmailLabel;
@property (nonatomic, weak) NSTextField *confirmEmailField;

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
	self.confirmEmailLabel = [self labelWithString:NSLocalizedString(@"Confirm Email Address", @"")];
	self.nameLabel = [self labelWithString:NSLocalizedString(@"Name", @"")];

	self.emailField = [self textFieldWithString:@""];
	self.confirmEmailField = [self textFieldWithString:@""];
	self.nameField = [self textFieldWithString:@""];

	@unsafeify(self);

	[self.emailField rac_bind:NSValueBinding toObject:self withKeyPath:@keypath(self.email) nilValue:@""];

	RAC(self.confirmEmailVisible) = [RACAble(self.email) map:^(NSString *str) {
		return @(str.length > 0);
	}];

	RAC(self.labelWidth) = [RACSignal max:@[
		self.nameLabel.rcl_intrinsicContentSizeSignal.width,
		self.emailLabel.rcl_intrinsicContentSizeSignal.width,
		self.confirmEmailLabel.rcl_intrinsicContentSizeSignal.width,
	]];

	RACSignal *verticalPadding = [RACSignal return:@8];

	RACTupleUnpack(RACSignal *emailRect, RACSignal *possibleConfirmEmailRect) = [[self.contentView.rcl_frameSignal
		insetWidth:[RACSignal return:@32] height:[RACSignal return:@16]]
		divideWithAmount:self.emailField.rcl_intrinsicContentSizeSignal.height padding:verticalPadding fromEdge:CGRectMaxYEdge];

	[self layoutField:self.emailField label:self.emailLabel fromSignal:emailRect];

	RACSignal *confirmHeightPlusPadding = [[RACAbleWithStart(self.confirmEmailVisible)
		map:^(NSNumber *visible) {
			@strongify(self);

			if (visible.boolValue) {
				return [self.confirmEmailField.rcl_intrinsicContentSizeSignal.height plus:verticalPadding];
			} else {
				return [RACSignal return:@0];
			}
		}]
		switch];

	RACTupleUnpack(RACSignal *confirmEmailRect, RACSignal *nameRect) = [possibleConfirmEmailRect divideWithAmount:confirmHeightPlusPadding fromEdge:CGRectMaxYEdge];

	confirmEmailRect = [confirmEmailRect remainderAfterSlicingAmount:verticalPadding fromEdge:CGRectMinYEdge];
	[self layoutField:self.confirmEmailField label:self.confirmEmailLabel fromSignal:confirmEmailRect];

	nameRect = [nameRect sliceWithAmount:self.nameField.rcl_intrinsicContentSizeSignal.height fromEdge:CGRectMaxYEdge];
	[self layoutField:self.nameField label:self.nameLabel fromSignal:nameRect];
}

- (void)layoutField:(NSTextField *)field label:(NSTextField *)label fromSignal:(RACSignal *)signal {
	RACSignal *horizontalPadding = [RACSignal return:@8];

	RACTupleUnpack(RACSignal *labelRect, RACSignal *fieldRect) = [signal divideWithAmount:RACAbleWithStart(self.labelWidth) padding:horizontalPadding fromEdge:CGRectMinXEdge];

	RAC(field, rcl_alignmentRect) = fieldRect;
	RAC(label, rcl_alignmentRect) = [[labelRect replaceSize:label.rcl_intrinsicContentSizeSignal]
		alignBaseline:label.rcl_baselineSignal toBaseline:field.rcl_baselineSignal ofRect:fieldRect];
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
