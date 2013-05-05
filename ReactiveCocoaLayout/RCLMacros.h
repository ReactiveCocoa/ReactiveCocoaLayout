//
//  RCLMacros.h
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2013-05-04.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <ReactiveCocoa/metamacros.h>

#define RCLAlign(RECTS, ...) \
	(^ RACSignal * (RACSignal *rcl_signal_) { \
		metamacro_foreach_concat(RCLAlign_,, __VA_ARGS__) \
		\
		return rcl_signal_; \
	})(RECTS)

#define RCLAlign_left(SIGNAL) \
	rcl_signal_ = [rcl_signal_ alignAttribute:NSLayoutAttributeLeft to:(SIGNAL)];

#define RCLAlign_right(SIGNAL) \
	rcl_signal_ = [rcl_signal_ alignAttribute:NSLayoutAttributeRight to:(SIGNAL)];

#define RCLAlign_width(SIGNAL) \
	rcl_signal_ = [rcl_signal_ alignAttribute:NSLayoutAttributeWidth to:(SIGNAL)];

#define RCLAlign_height(SIGNAL) \
	rcl_signal_ = [rcl_signal_ alignAttribute:NSLayoutAttributeHeight to:(SIGNAL)];
