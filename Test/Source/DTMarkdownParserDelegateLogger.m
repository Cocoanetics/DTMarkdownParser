//
//  DTMarkdownParserDelegateLogger.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParserDelegateLogger.h"
#import "DTMarkdownParserDelegateLogMessage.h"
#import "DTMarkdownParser.h"
#import "NSInvocation+DTFoundation.h"

#import <objc/runtime.h>


@implementation DTMarkdownParserDelegateLogger
{
	NSMutableArray *_log;
}

- (instancetype)init
{
	self = [super init];
	
	if (self)
	{
	}
	
	return self;
}

- (void)_logSelector:(SEL)selector parameters:(NSArray *)parameters
{
	if (!_log)
	{
		_log = [NSMutableArray new];
	}
	
	DTMarkdownParserDelegateLogMessage *msg = [[DTMarkdownParserDelegateLogMessage alloc] initWithSelector:NSStringFromSelector(selector) parameters:parameters];
	[_log addObject:msg];
}


#pragma mark - DTMarkdownParserDelegate

- (BOOL)respondsToSelector:(SEL)aSelector
{
	struct objc_method_description hasMethod = protocol_getMethodDescription(@protocol(DTMarkdownParserDelegate), aSelector, NO, YES);

	if (hasMethod.name != nil)
	{
		return YES;
	}
	
	return [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector
{
    NSMethodSignature *theMethodSignature = [super methodSignatureForSelector:inSelector];
	
    if (!theMethodSignature)
    {
        struct objc_method_description theDescription = protocol_getMethodDescription(@protocol(DTMarkdownParserDelegate),inSelector, NO, YES);
		
        theMethodSignature = [NSMethodSignature signatureWithObjCTypes:theDescription.types];
    }
	
    return(theMethodSignature);
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	NSUInteger numberOfArguments = anInvocation.methodSignature.numberOfArguments;

	NSMutableArray *tmpArray = [NSMutableArray array];
	
	anInvocation.target = nil;
	[anInvocation retainArguments];
	
	SEL selector;
	[anInvocation getArgument:&selector atIndex:1];
	
	for (NSUInteger idx = 2; idx<numberOfArguments; idx++)
	{
		id argument = [anInvocation getArgumentAtIndexAsObject:idx];
		[tmpArray addObject:[argument description]];
	}
	
	if (![tmpArray count])
	{
		tmpArray = nil;
	}
	
	[self _logSelector:selector parameters:nil];
	
	[anInvocation invokeWithTarget:nil];
}

#pragma mark - Properties

- (NSArray *)log
{
	return [_log copy];
}

@end
