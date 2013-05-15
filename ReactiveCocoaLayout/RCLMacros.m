//
//  RCLMacros.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "RCLMacros.h"
#import "EXTScope.h"
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

	[[self rectSignalFromBindings:bindings forPropertyKey:property] toProperty:property onObject:self.view];
}

#pragma mark Attribute Parsing

- (RACSignal *)rectSignalFromBindings:(NSDictionary *)bindings forPropertyKey:(NSString *)property {
	NSParameterAssert(bindings != nil);
	NSParameterAssert(property != nil);

	NSArray *sortedAttributes = [bindings.allKeys sortedArrayUsingSelector:@selector(compare:)];

	RACSignal *signal = [self.view rcl_intrinsicBoundsSignal];
	for (NSNumber *attribute in sortedAttributes) {
		RACSignal *value = bindings[attribute];
		if (![value isKindOfClass:RACSignal.class]) {
			value = [RACSignal return:value];
		}

		NSAssert([attribute isKindOfClass:NSNumber.class], @"Layout binding key is not a RCLAttribute: %@", attribute);
		switch (attribute.integerValue) {
			case RCLAttributeRect:
				signal = [RACSignal combineLatest:@[ signal, value ] reduce:^(NSValue *baseRect, NSValue *overrideRect) {
					return overrideRect;
				}];

				break;

			case RCLAttributeSize:
				signal = [signal replaceSize:value];
				break;

			case RCLAttributeOrigin:
				signal = [signal replaceOrigin:value];
				break;

			case RCLAttributeCenter:
				signal = [signal alignCenter:value];
				break;

			case RCLAttributeWidth:
				signal = [signal alignAttribute:NSLayoutAttributeWidth to:value];
				break;

			case RCLAttributeHeight:
				signal = [signal alignAttribute:NSLayoutAttributeHeight to:value];
				break;

			case RCLAttributeCenterX:
				signal = [signal alignAttribute:NSLayoutAttributeCenterX to:value];
				break;

			case RCLAttributeCenterY:
				signal = [signal alignAttribute:NSLayoutAttributeCenterY to:value];
				break;

			case RCLAttributeBottom:
				signal = [signal alignAttribute:NSLayoutAttributeBottom to:value];
				break;

			case RCLAttributeRight:
				signal = [signal alignAttribute:NSLayoutAttributeRight to:value];
				break;

			case RCLAttributeTop:
				signal = [signal alignAttribute:NSLayoutAttributeTop to:value];
				break;

			case RCLAttributeLeft:
				signal = [signal alignAttribute:NSLayoutAttributeLeft to:value];
				break;

			case RCLAttributeTrailing:
				signal = [signal alignAttribute:NSLayoutAttributeTrailing to:value];
				break;

			case RCLAttributeLeading:
				signal = [signal alignAttribute:NSLayoutAttributeLeading to:value];
				break;

			case RCLAttributeBaseline: {
				value = [[value publish] autoconnect];

				NSString *propertySignalKey = [property stringByAppendingString:@"Signal"];
				RACSignal *referenceRect = [[value
					map:^(id view) {
						return [view valueForKey:propertySignalKey];
					}]
					switchToLatest];

				RACSignal *referenceBaseline = [[value
					map:^(id view) {
						return [view rcl_baselineSignal];
					}]
					switchToLatest];

				signal = [signal alignBaseline:[self.view rcl_baselineSignal] toBaseline:referenceBaseline ofRect:referenceRect];
				break;
			}

			default:
				NSAssert(NO, @"Unrecognized RCLAttribute: %@", attribute);
		}
	}

	return signal;
}

@end
