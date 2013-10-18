//
//  DTInvocationRecorder.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTInvocationRecorder.h"

#import <objc/runtime.h>

@implementation DTInvocationRecorder
{
	NSMutableArray *_protocols;
	
	NSMutableArray *_invocations;
}

- (void)addProtocol:(Protocol *)protocol
{
	if (!_protocols)
	{
		_protocols = [NSMutableArray new];
	}
	
	[_protocols addObject:protocol];
}

- (NSArray *)invocationsMatchingSelector:(SEL)selector
{
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSInvocation *invocation, NSDictionary *bindings) {
		return (invocation.selector == selector);
	}];
	
	return [_invocations filteredArrayUsingPredicate:predicate];
}


#pragma mark - Magic

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
	return [_protocols containsObject:aProtocol];
}

- (Protocol *)_protocolContainingSelector:(SEL)selector
{
	for (Protocol *protocol in _protocols)
	{
		struct objc_method_description hasMethod = protocol_getMethodDescription(protocol, selector, NO, YES);
		
		if (hasMethod.name != nil)
		{
			return protocol;
		}
	}
	
	return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
	{
		return YES;
	}
	
	Protocol *protocol = [self _protocolContainingSelector:aSelector];
	
	if (protocol)
	{
		return YES;
	}
	
	return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *methodSignature = [super methodSignatureForSelector:selector];
	
    if (methodSignature)
    {
		return methodSignature;
	}
		
	Protocol *protocol = [self _protocolContainingSelector:selector];
		
	if (protocol)
	{
        struct objc_method_description theDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
		
        return [NSMethodSignature signatureWithObjCTypes:theDescription.types];

	}

	return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	[invocation retainArguments];
	
	if (!_invocations)
	{
		_invocations = [[NSMutableArray alloc] init];
	}
	
	[_invocations addObject:invocation];
}


@end
