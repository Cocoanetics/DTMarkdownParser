//
//  DTInvocationTestFunctions.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTInvocationTestFunctions.h"
#import "NSInvocation+DTFoundation.h"

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
			id argument = [invocation argumentAtIndexAsObject:i];
			
			if ([argument isEqual:parameter])
			{
				return YES;
			}
		}
	}
	
	return NO;
}
