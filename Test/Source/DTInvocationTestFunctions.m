//
//  DTInvocationTestFunctions.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTInvocationTestFunctions.h"

BOOL DTInvocationRecorderContainsCallWithParameter(DTInvocationRecorder *recorder, SEL selector, id parameter)
{
	NSArray *invocations = [recorder invocationsMatchingSelector:selector];
	
	if (![invocations count])
	{
		return NO;
	}
	
	NSInvocation *firstInvocation = invocations[0];
	
	if (firstInvocation.selector != selector)
	{
		return NO;
	}
	
	// no parameter, but method found == success
	if (!parameter)
	{
		return YES;
	}
	
	for (NSInvocation *invocation in invocations)
	{
		NSUInteger numberOfArguments = [invocation.methodSignature numberOfArguments];
		
		for (NSUInteger i=2; i<numberOfArguments; i++)
		{
			const char *type = [invocation.methodSignature getArgumentTypeAtIndex:i];
			
			if (type[0] == '@')
			{
				__unsafe_unretained id arg;
				[invocation getArgument:&arg atIndex:i];
				
				if ([arg isEqual:parameter])
				{
					return YES;
				}
			}
		}
	}
	
	return NO;
}
