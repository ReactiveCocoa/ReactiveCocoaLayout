//
//  RCLMacros.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "RCLMacros.h"
#import "RACSignal+RCLGeometryAdditions.h"
#import "View+RCLAutoLayoutAdditions.h"

@interface RCLRectAssignmentTrampoline ()

// The view that the receiver was initialized with.
@property (nonatomic, strong) id view;

@end

@implementation RCLRectAssignmentTrampoline : NSObject

#pragma mark Lifecycle

+ (instancetype)trampolineWithView:(id)view {
	if (view == nil) return nil;

	RCLRectAssignmentTrampoline *trampoline = [[self alloc] init];
	trampoline.view = view;
	return trampoline;
}

#pragma mark Subscripting

- (RACSignal *)objectForKeyedSubscript:(NSString *)property {
	NSParameterAssert(property != nil);

	return [self.view valueForKey:[property stringByAppendingString:@"Signal"]];
}

- (void)setObject:(NSDictionary *)bindings forKeyedSubscript:(NSString *)property {
	NSParameterAssert(property != nil);
	NSParameterAssert([bindings isKindOfClass:NSDictionary.class]);

	[[self rectSignalFromBindings:bindings] toProperty:property onObject:self.view];
}

#pragma mark Attribute Parsing

- (RACSignal *)rectSignalFromBindings:(NSDictionary *)bindings {
	NSParameterAssert(bindings != nil);

	__block RACSignal *signal = [self.view rcl_intrinsicBoundsSignal];

	[bindings enumerateKeysAndObjectsUsingBlock:^(NSNumber *attribute, id value, BOOL *stop) {
		NSAssert([attribute isKindOfClass:NSNumber.class], @"Layout binding key is not an NSLayoutAttribute: %@", attribute);

		if ([value isKindOfClass:NSValue.class]) {
			value = [RACSignal return:value];
		}

		NSAssert([value isKindOfClass:RACSignal.class], @"Layout binding value is not a signal or geometry value: %@", value);
		signal = [signal alignAttribute:attribute.integerValue to:value];
	}];

	return signal;
}

@end
