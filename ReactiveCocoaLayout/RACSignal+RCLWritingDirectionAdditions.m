//
//  RACSignal+RCLWritingDirectionAdditions.m
//  ReactiveCocoaLayout
//
//  Created by Justin Spahr-Summers on 2012-12-18.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "RACSignal+RCLWritingDirectionAdditions.h"
#import "NSNotificationCenter+RACSupport.h"

// Returns a signal which sends the line direction for the current language,
// and automatically re-sends it any time the current locale changes.
static RACSignal *lineDirectionSignal(void) {
	return [[[[NSNotificationCenter.defaultCenter rac_addObserverForName:NSCurrentLocaleDidChangeNotification object:nil]
		startWith:nil]
		map:^(id _) {
			return [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode];
		}]
		map:^(NSString *languageCode) {
			return @([NSLocale lineDirectionForLanguage:languageCode]);
		}];
}

@implementation RACSignal (RCLWritingDirectionAdditions)

+ (RACSignal *)leadingEdgeSignal {
	return [lineDirectionSignal() map:^(NSNumber *direction) {
		if (direction.unsignedIntegerValue == NSLocaleLanguageDirectionRightToLeft) {
			return @(CGRectMaxXEdge);
		} else {
			return @(CGRectMinXEdge);
		}
	}];
}

+ (RACSignal *)trailingEdgeSignal {
	return [lineDirectionSignal() map:^(NSNumber *direction) {
		if (direction.unsignedIntegerValue == NSLocaleLanguageDirectionRightToLeft) {
			return @(CGRectMinXEdge);
		} else {
			return @(CGRectMaxXEdge);
		}
	}];
}

@end
