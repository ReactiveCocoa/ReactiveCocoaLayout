//
//  RCLMacros.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "RCLMacros.h"
#import "RACSignal+RCLGeometryAdditions.h"
#import <Archimedes/Archimedes.h>
#import <ReactiveCocoa/EXTScope.h>

#ifdef RCL_FOR_IPHONE
#import "UIView+RCLGeometryAdditions.h"
#else
#import "NSView+RCLGeometryAdditions.h"
#endif

static NSString *NSStringFromRCLAttribute(RCLAttribute attribute) __attribute__((unused)) {
	switch (attribute) {
		case RCLAttributeRect: return @"rcl_rect";
		case RCLAttributeSize: return @"rcl_size";
		case RCLAttributeOrigin: return @"rcl_origin";
		case RCLAttributeHeight: return @"rcl_height";
		case RCLAttributeWidth: return @"rcl_width";
		case RCLAttributeCenter: return @"rcl_center";
		case RCLAttributeCenterX: return @"rcl_centerX";
		case RCLAttributeCenterY: return @"rcl_centerY";
		case RCLAttributeBottom: return @"rcl_bottom";
		case RCLAttributeRight: return @"rcl_right";
		case RCLAttributeTop: return @"rcl_top";
		case RCLAttributeLeft: return @"rcl_left";
		case RCLAttributeTrailing: return @"rcl_trailing";
		case RCLAttributeLeading: return @"rcl_leading";
		case RCLAttributeBaseline: return @"rcl_baseline";
	}
}

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

	[[self rectSignalFromBindings:bindings] setKeyPath:property onObject:self.view];
}

#pragma mark Attribute Parsing

- (RACSignal *)rectSignalFromBindings:(NSDictionary *)bindings {
	NSParameterAssert(bindings != nil);

	NSArray *sortedAttributes = [bindings.allKeys sortedArrayUsingSelector:@selector(compare:)];
	RACSignal *signal = [RACSignal return:MEDBox([self.view frame])];

	BOOL widthAssigned = NO;
	BOOL heightAssigned = NO;
	BOOL xAssigned = NO;
	BOOL yAssigned = NO;
	for (NSNumber *attribute in sortedAttributes) {
		NSAssert([attribute isKindOfClass:NSNumber.class], @"Layout binding key is not a RCLAttribute: %@", attribute);

		RACSignal *value = bindings[attribute];
		if (![value isKindOfClass:RACSignal.class]) {
			value = [self signalWithConstantValue:value forAttribute:attribute.integerValue];
		}

		switch (attribute.integerValue) {
			case RCLAttributeRect:
				widthAssigned = heightAssigned = xAssigned = yAssigned = YES;
				signal = value;
				break;

			case RCLAttributeSize:
				widthAssigned = heightAssigned = YES;
				signal = [signal replaceSize:value];
				break;

			case RCLAttributeOrigin:
				xAssigned = yAssigned = YES;
				signal = [signal replaceOrigin:value];
				break;

			case RCLAttributeCenter:
				xAssigned = yAssigned = YES;
				signal = [signal alignCenter:value];
				break;

			case RCLAttributeWidth:
				widthAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeWidth to:value];
				break;

			case RCLAttributeHeight:
				heightAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeHeight to:value];
				break;

			case RCLAttributeCenterX:
				xAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeCenterX to:value];
				break;

			case RCLAttributeCenterY:
				yAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeCenterY to:value];
				break;

			case RCLAttributeBottom:
				yAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeBottom to:value];
				break;

			case RCLAttributeRight:
				xAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeRight to:value];
				break;

			case RCLAttributeTop:
				yAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeTop to:value];
				break;

			case RCLAttributeLeft:
				xAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeLeft to:value];
				break;

			case RCLAttributeTrailing:
				xAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeTrailing to:value];
				break;

			case RCLAttributeLeading:
				xAssigned = YES;
				signal = [signal alignAttribute:NSLayoutAttributeLeading to:value];
				break;

			case RCLAttributeBaseline: {
				yAssigned = YES;
				value = [value replayLast];

				RACSignal *referenceRect = [[value
					map:^(id view) {
						return [view rcl_alignmentRectSignal];
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
		}
	}

	@weakify(self);
	return [signal map:^(NSValue *value) {
		@strongify(self);
		CGRect frame = value.med_rectValue;
		CGRect newFrame = frame;
		if (!xAssigned) newFrame.origin.x = [self.view frame].origin.x;
		if (!yAssigned) newFrame.origin.y = [self.view frame].origin.y;
		if (!widthAssigned) newFrame.size.width = [self.view frame].size.width;
		if (!heightAssigned) newFrame.size.height = [self.view frame].size.height;
		return MEDBox(newFrame);
	}];
}

- (RACSignal *)signalWithConstantValue:(id)value forAttribute:(RCLAttribute)attribute {
	NSParameterAssert(value != nil);

	switch (attribute) {
		case RCLAttributeRect:
			NSAssert([value isKindOfClass:NSValue.class] && [value med_geometryStructType] == MEDGeometryStructTypeRect, @"Expected a CGRect for attribute %@, got %@", NSStringFromRCLAttribute(attribute), value);
			break;

		case RCLAttributeSize:
			NSAssert([value isKindOfClass:NSValue.class] && [value med_geometryStructType] == MEDGeometryStructTypeSize, @"Expected a CGSize for attribute %@, got %@", NSStringFromRCLAttribute(attribute), value);
			break;

		case RCLAttributeOrigin:
		case RCLAttributeCenter:
			NSAssert([value isKindOfClass:NSValue.class] && [value med_geometryStructType] == MEDGeometryStructTypePoint, @"Expected a CGPoint for attribute %@, got %@", NSStringFromRCLAttribute(attribute), value);
			break;

		case RCLAttributeBaseline: {
			#ifdef RCL_FOR_IPHONE
			Class expectedClass __attribute__((unused)) = UIView.class;
			#else
			Class expectedClass __attribute__((unused)) = NSView.class;
			#endif

			NSAssert([value isKindOfClass:expectedClass], @"Expected a view for attribute %@, got %@", NSStringFromRCLAttribute(attribute), value);
			break;
		}

		default:
			NSAssert([value isKindOfClass:NSNumber.class], @"Expected a CGFloat for attribute %@, got %@", NSStringFromRCLAttribute(attribute), value);
	}

	return [RACSignal return:value];
}

@end
