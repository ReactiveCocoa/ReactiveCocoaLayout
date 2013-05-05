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

	// Width and height attributes need to be applied before others, since they
	// may affect coordinate calculations.
	BOOL (^layoutAttributeIsForSize)(NSLayoutAttribute) = ^ BOOL (NSLayoutAttribute attribute) {
		return attribute == NSLayoutAttributeWidth || attribute == NSLayoutAttributeHeight;
	};

	NSArray *sortedAttributes = [bindings.allKeys sortedArrayUsingComparator:^(NSNumber *attribA, NSNumber *attribB) {
		NSAssert([attribA isKindOfClass:NSNumber.class], @"Layout binding key is not an NSLayoutAttribute: %@", attribA);
		NSAssert([attribB isKindOfClass:NSNumber.class], @"Layout binding key is not an NSLayoutAttribute: %@", attribB);

		if (layoutAttributeIsForSize(attribA.integerValue)) {
			return NSOrderedAscending;
		} else if (layoutAttributeIsForSize(attribB.integerValue)) {
			return NSOrderedDescending;
		} else {
			return NSOrderedSame;
		}
	}];

	RACSignal *signal = [self.view rcl_intrinsicBoundsSignal];
	for (NSNumber *attribute in sortedAttributes) {
		id value = bindings[attribute];

		if ([value isKindOfClass:NSValue.class]) {
			value = [RACSignal return:value];
		}

		NSAssert([value isKindOfClass:RACSignal.class], @"Layout binding value is not a signal or geometry value: %@", value);
		signal = [signal alignAttribute:attribute.integerValue to:value];
	}

	return signal;
}

@end
