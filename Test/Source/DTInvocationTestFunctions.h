//
//  DTInvocationTestFunctions.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTInvocationRecorder.h"

BOOL DTInvocationRecorderContainsCallWithParameter(DTInvocationRecorder *recorder, SEL selector, id parameter);


#define DTAssertInvocationRecorderContainsCallWithParameter(recorder, selector, parameter) \
do { \
	BOOL _evaluatedExpression = !!(DTInvocationRecorderContainsCallWithParameter(recorder, selector, parameter));\
	if (!_evaluatedExpression) {\
		[self recordFailureWithDescription:[NSString stringWithFormat:@"No call to %@ with parameter '%@' was recorded", NSStringFromSelector(selector), parameter] \
									inFile:[NSString stringWithUTF8String:__FILE__] \
									atLine:__LINE__ \
								  expected:YES]; \
	} \
} while (0)
