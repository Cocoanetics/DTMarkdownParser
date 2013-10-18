//
//  DTInvocationTestFunctions.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTInvocationRecorder.h"

BOOL DTInvocationRecorderContainsCallWithParameter(DTInvocationRecorder *recorder, SEL selector, id parameter);


#define DTAssertRecorderContainsCallWithParameter(recorder, selector, parameter) \
do { \
BOOL _evaluatedExpression = !!(DTInvocationRecorderContainsCallWithParameter(recorder, selector, parameter));\
if (!_evaluatedExpression) {\
[self failWithException:([NSException failureInCondition:[NSString stringWithFormat:@"Assertion that a call to %@ with parameter '%@' exists", NSStringFromSelector(selector), parameter] \
isTrue:NO \
inFile:[NSString stringWithUTF8String:__FILE__] \
atLine:__LINE__ \
withDescription:[NSString stringWithFormat:@"No such call was recorded"]])]; \
} \
} while (0)