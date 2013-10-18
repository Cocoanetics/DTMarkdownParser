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
		unsigned int supportsStartTag:1;
		unsigned int supportsEndTag:1;
	} _delegateFlags;
	
	// parsing state
	NSMutableArray *_tagStack;
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

#pragma mark - Parsing Helpers

- (void)_reportBeginOfTag:(NSString *)tag attributes:(NSDictionary *)attributes
{
	if (_delegateFlags.supportsStartTag)
	{
		[_delegate parser:self didStartElement:tag attributes:attributes];
	}
}

- (void)_reportEndOfTag:(NSString *)tag
{
	if (_delegateFlags.supportsStartTag)
	{
		[_delegate parser:self didEndElement:tag];
	}
}

- (void)_pushTag:(NSString *)tag attributes:(NSDictionary *)attributes
{
	[_tagStack addObject:tag];
	[self _reportBeginOfTag:tag attributes:attributes];
}

- (void)_popTag
{
	NSString *tag = [self _currentTag];
	
	[self _reportEndOfTag:tag];
	[_tagStack removeLastObject];
}

- (NSString *)_currentTag
{
	return [_tagStack lastObject];
}


#pragma mark - Parsing

- (BOOL)parse
{
	if (!_string)
	{
		return NO;
	}
	
	_tagStack = [NSMutableArray new];
	
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

				[self _pushTag:@"p" attributes:nil];
				
				if (line)
				{
					[_delegate parser:self foundCharacters:line];
				}
				else
				{
					NSLog(@"empty line");
				}
				
				[self _popTag];
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
	_delegateFlags.supportsStartTag = ([_delegate respondsToSelector:@selector(parser:didStartElement:attributes:)]);
	_delegateFlags.supportsEndTag = ([_delegate respondsToSelector:@selector(parser:didEndElement:)]);
}

@end
