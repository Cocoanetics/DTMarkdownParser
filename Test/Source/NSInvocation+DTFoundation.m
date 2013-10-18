//
//  NSInvocation+DTFoundation.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSInvocation+DTFoundation.h"

@implementation NSInvocation (DTFoundation)

- (id)getArgumentAtIndexAsObject:(NSUInteger)argIndex
{
	const char* argType;
	
	argType = [[self methodSignature] getArgumentTypeAtIndex:argIndex];
	while(strchr("rnNoORV", argType[0]) != NULL)
		argType += 1;
	
	if((strlen(argType) > 1) && (strchr("{^", argType[0]) == NULL) && (strcmp("@?", argType) != 0))
		[NSException raise:NSInvalidArgumentException format:@"Cannot handle argument type '%s'.", argType];
	
	switch (argType[0])
	{
		case '#':
		case '@':
		{
			id value;
			[self getArgument:&value atIndex:argIndex];
			return value;
		}
		case ':':
 		{
 			SEL s = (SEL)0;
 			[self getArgument:&s atIndex:argIndex];
 			id value = NSStringFromSelector(s);
 			return value;
 		}
		case 'i':
		{
			int value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithInt:value];
		}
		case 's':
		{
			short value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithShort:value];
		}
		case 'l':
		{
			long value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithLong:value];
		}
		case 'q':
		{
			long long value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithLongLong:value];
		}
		case 'c':
		{
			char value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithChar:value];
		}
		case 'C':
		{
			unsigned char value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithUnsignedChar:value];
		}
		case 'I':
		{
			unsigned int value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithUnsignedInt:value];
		}
		case 'S':
		{
			unsigned short value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithUnsignedShort:value];
		}
		case 'L':
		{
			unsigned long value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithUnsignedLong:value];
		}
		case 'Q':
		{
			unsigned long long value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithUnsignedLongLong:value];
		}
		case 'f':
		{
			float value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithFloat:value];
		}
		case 'd':
		{
			double value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithDouble:value];
		}
		case 'B':
		{
			bool value;
			[self getArgument:&value atIndex:argIndex];
			return [NSNumber numberWithBool:value];
		}
		case '^':
        {
            void *value = NULL;
            [self getArgument:&value atIndex:argIndex];
            return [NSValue valueWithPointer:value];
        }
		case '{': // structure
		{
			NSUInteger maxArgSize = [[self methodSignature] frameLength];
			NSMutableData *argumentData = [[NSMutableData alloc] initWithLength:maxArgSize];
			[self getArgument:[argumentData mutableBytes] atIndex:argIndex];
			return [NSValue valueWithBytes:[argumentData bytes] objCType:argType];
		}
			
	}
	
	[NSException raise:NSInvalidArgumentException format:@"Argument type '%s' not supported", argType];
	return nil;
}

@end
