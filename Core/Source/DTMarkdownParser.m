//
//  DTMarkdownParser.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"

@implementation DTMarkdownParser
{
	NSString *_string;
	
	// lookup bitmask what delegate methods are implemented
	struct
	{
		unsigned int supportsStartDocument:1;
		unsigned int supportsEndDocument:1;
		unsigned int supportsFoundCharacters:1;
	} _delegateFlags;
}

- (instancetype)initWithString:(NSString *)string
{
	self = [super init];
	
	if (self)
	{
		_string = [string copy];
	}
	
	return self;
}

#pragma mark - Parsing

- (BOOL)parse
{
	if (!_string)
	{
		return NO;
	}
	
	if (_delegateFlags.supportsStartDocument)
	{
		[_delegate parserDidStartDocument:self];
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	while (![scanner isAtEnd])
	{
		NSString *line;
		if ([scanner scanUpToString:@"\n" intoString:&line])
		{
			BOOL hasNL = [scanner scanString:@"\n" intoString:NULL];
			
			if (_delegateFlags.supportsFoundCharacters)
			{
				if (hasNL)
				{
					line = [line stringByAppendingString:@"\n"];
				}
				
				if (line)
				{
					[_delegate parser:self foundCharacters:line];
				}
				else
				{
					NSLog(@"empty line");
				}
			}
		}
	}
	
	if (_delegateFlags.supportsEndDocument)
	{
		[_delegate parserDidEndDocument:self];
	}
	
	return YES;
}

- (BOOL)_parseDocument
{
	BOOL result = YES;
	
	return result;
}

#pragma mark - Properties

- (void)setDelegate:(id<DTMarkdownParserDelegate>)delegate
{
	_delegate = delegate;
	
	_delegateFlags.supportsStartDocument = ([_delegate respondsToSelector:@selector(parserDidStartDocument:)]);
	_delegateFlags.supportsEndDocument = ([_delegate respondsToSelector:@selector(parserDidEndDocument:)]);
	_delegateFlags.supportsFoundCharacters = ([_delegate respondsToSelector:@selector(parser:foundCharacters:)]);
}

@end
