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
	DTMarkdownParserOptions _options;
	
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
	
	// lookup dictionary for special lines
	NSMutableDictionary *_specialLines;
	NSMutableIndexSet *_ignoredLines;
}

- (instancetype)initWithString:(NSString *)string options:(DTMarkdownParserOptions)options
{
	self = [super init];
	
	if (self)
	{
		_string = [string copy];
		_options = options;
	}
	
	return self;
}

#pragma mark - Communication with Delegate

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

- (void)_reportCharacters:(NSString *)string
{
	if (_delegateFlags.supportsFoundCharacters)
	{
		[_delegate parser:self foundCharacters:string];
	}
}

#pragma mark - Parsing Helpers

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

- (BOOL)_currentTagIsBlock
{
	NSString *tag = [_tagStack lastObject];
	
	if ([tag isEqualToString:@"p"])
	{
		return YES;
	}
	
	if ([tag isEqualToString:@"blockquote"])
	{
		return YES;
	}
	
	return NO;
}

- (NSString *)_effectiveMarkerPrefixOfString:(NSString *)string
{
	if ([string hasPrefix:@"**"])
	{
		return @"**";
	}
	else if ([string hasPrefix:@"*"])
	{
		return @"*";
	}
	else if ([string hasPrefix:@"__"])
	{
		return @"__";
	}
	else if ([string hasPrefix:@"_"])
	{
		return @"_";
	}
	
	return nil;
}

- (void)_processMarkedString:(NSString *)markedString insideMarker:(NSString *)marker
{
	NSAssert([markedString hasPrefix:marker] && [markedString hasSuffix:marker], @"Processed string has to have the marker at beginning and end");
	
	NSUInteger markerLength = [marker length];
	NSRange insideMarkedRange = NSMakeRange(markerLength, markedString.length - 2*markerLength);
	
	// trim off prefix and suffix marker
	markedString = [markedString substringWithRange:insideMarkedRange];
	
	// open the tag for this marker
	if ([marker isEqualToString:@"*"] || [marker isEqualToString:@"_"])
	{
		[self _pushTag:@"em" attributes:nil];
	}
	else if ([marker isEqualToString:@"**"] || [marker isEqualToString:@"__"])
	{
		[self _pushTag:@"strong" attributes:nil];
	}
	
	// see if there is another marker
	NSString *furtherMarker = [self _effectiveMarkerPrefixOfString:markedString];
	
	if (furtherMarker && [markedString hasSuffix:furtherMarker])
	{
		[self _processMarkedString:markedString insideMarker:furtherMarker];
	}
	else
	{
		[self _reportCharacters:markedString];
	}
	
	// close the tag for this marker
	[self _popTag];
}

- (void)_processLine:(NSString *)line
{
	NSScanner *scanner = [NSScanner scannerWithString:line];
	scanner.charactersToBeSkipped = nil;
	
	NSCharacterSet *markerChars = [NSCharacterSet characterSetWithCharactersInString:@"*_"];
	
	while (![scanner isAtEnd])
	{
		NSString *part;
		
		// scan part before first marker
		if ([scanner scanUpToCharactersFromSet:markerChars intoString:&part])
		{
			// output part before markers
			[self _reportCharacters:part];
		}
		
		// scan marker
		NSString *openingMarkers;
		
		NSRange markedRange = NSMakeRange(scanner.scanLocation, 0);
		
		if ([scanner scanCharactersFromSet:markerChars intoString:&openingMarkers])
		{
			NSString *enclosedPart;
			NSString *closingMarkersToLookFor = [self _effectiveMarkerPrefixOfString:openingMarkers];
			
			NSAssert(closingMarkersToLookFor, @"There should be a closing marker to look for because we only get here from having scanned for marker characters");
			
			// see if this encloses something
			if ([scanner scanUpToString:closingMarkersToLookFor intoString:&enclosedPart])
			{
				// there has to be a closing marker as well
				if ([scanner scanString:closingMarkersToLookFor intoString:NULL])
				{
					markedRange.length = scanner.scanLocation - markedRange.location;
					NSString *markedString = [line substringWithRange:markedRange];
					
					[self _processMarkedString:markedString insideMarker:closingMarkersToLookFor];
				}
				else
				{
					// output as is, not enclosed
					NSString *joined = [closingMarkersToLookFor stringByAppendingString:enclosedPart];
					
					[self _reportCharacters:joined];
				}
			}
			else
			{
				// did not enclose anything
				[self _reportCharacters:openingMarkers];
			}
		}
	}
}

- (void)_findAndMarkSpecialLines
{
	_ignoredLines = [NSMutableIndexSet new];
	_specialLines = [NSMutableDictionary new];
	
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	NSUInteger lineIndex = 0;
	while (![scanner isAtEnd])
	{
		NSString *line;
		if ([scanner scanUpToString:@"\n" intoString:&line])
		{
			NSLog(@"%lu: %@", (unsigned long)lineIndex, line);
			
			
			BOOL didFindSpecial = NO;
			
			if (lineIndex)
			{
				unichar firstChar = [line characterAtIndex:0];
				
				if (firstChar=='-' || firstChar=='=')
				{
					line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSUInteger lineLen = [line length];
					
					NSUInteger idx=0;
					while (idx<lineLen && [line characterAtIndex:idx] == firstChar)
					{
						idx++;
					}
					
					if (idx>=lineLen)
					{
						// full line is this character
						[_ignoredLines addIndex:lineIndex];
						
						if (firstChar=='=')
						{
							_specialLines[@(lineIndex-1)] = @"H1";
							didFindSpecial = YES;
						}
						else if (firstChar=='-')
						{
							_specialLines[@(lineIndex-1)] = @"H2";
							didFindSpecial = YES;
						}
					}
				}
			}
			
			if (!didFindSpecial)
			{
				NSCharacterSet *ruleCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" -*\n"];
				
				if ([[line stringByTrimmingCharactersInSet:ruleCharacterSet] length]==0)
				{
					_specialLines[@(lineIndex)] = @"HR";
					didFindSpecial = YES;
				}
			}
		}
		
		if ([scanner scanString:@"\n" intoString:NULL])
		{
			lineIndex++;
		}
	}
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
	
	[self _findAndMarkSpecialLines];
	
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	NSUInteger lineIndex = 0;
	
	while (![scanner isAtEnd])
	{
		NSString *line;
		if ([scanner scanUpToString:@"\n" intoString:&line])
		{
			if ([line hasSuffix:@"\r"])
			{
				// cut off Windows \r
				line = [line substringWithRange:NSMakeRange(0, [line length]-1)];
			}
			
			BOOL hasNL = [scanner scanString:@"\n" intoString:NULL];
			
			if (![_ignoredLines containsIndex:lineIndex] && [line length])
			{
				
				BOOL hasTwoNL = NO;
				
				BOOL needsBR = NO;
				
				if (hasNL)
				{
					// Windows-style NL
					hasTwoNL = [scanner scanString:@"\r\n" intoString:NULL];
					
					if (!hasTwoNL)
					{
						// Unix-style NL
						hasTwoNL = [scanner scanString:@"\n" intoString:NULL];
					}
				}
				
				BOOL needsPushTag = NO;
				NSString *tag = nil;
				NSUInteger headerLevel = 0;
				
				if ([line hasPrefix:@">"])
				{
					tag = @"blockquote";
					
					if (![[self _currentTag] isEqualToString:@"blockquote"])
					{
						needsPushTag = YES;
					}
				}
				else if ([line hasPrefix:@"#"])
				{
					while ([line hasPrefix:@"#"])
					{
						headerLevel++;
						
						line = [line substringFromIndex:1];
					}
					
					// trim off leading spaces
					while ([line hasPrefix:@" "])
					{
						line = [line substringFromIndex:1];
					}
					
					// trim off trailing hashes
					while ([line hasSuffix:@"#"])
					{
						line = [line substringToIndex:[line length]-1];
					}
					
					// trim off trailing spaces
					while ([line hasSuffix:@" "])
					{
						line = [line substringToIndex:[line length]-1];
					}
				}
				else
				{
					tag = @"p";
				}
				
				NSString *specialLine = _specialLines[@(lineIndex)];
				BOOL shouldOutputLineText = YES;
				
				if ([specialLine isEqualToString:@"H1"])
				{
					headerLevel = 1;
				}
				else if ([specialLine isEqualToString:@"H2"])
				{
					headerLevel = 2;
				}
				else if ([specialLine isEqualToString:@"HR"])
				{
					tag = @"hr";
					shouldOutputLineText = NO;
				}
				
				if (headerLevel)
				{
					tag = [NSString stringWithFormat:@"h%d", (int)headerLevel];
				}
				
				// handle new lines
				if (shouldOutputLineText && !hasTwoNL && ![scanner isAtEnd])
				{
					// not a paragraph break
					
					if (_options & DTMarkdownParserOptionGitHubLineBreaks)
					{
						needsBR = YES;
					}
					else
					{
						if ([line hasSuffix:@"  "])
						{
							// two spaces at end of line are "Gruber-style BR"
							needsBR = YES;
							
							// trim off trailing spaces
							while ([line hasSuffix:@" "])
							{
								line = [line substringToIndex:[line length]-1];
							}
						}
						else if (!headerLevel)
						{
							line = [line stringByAppendingString:@"\n"];
						}
					}
				}
				
				if (![[self _currentTag] isEqualToString:tag])
				{
					needsPushTag = YES;
				}
				
				if (needsPushTag)
				{
					[self _pushTag:tag attributes:nil];
				}
				
				if (shouldOutputLineText)
				{
					if (line)
					{
						if ([tag isEqualToString:@"blockquote"])
						{
							if ([line hasPrefix:@">"])
							{
								line = [line substringFromIndex:1];
							}
							
							if ([line hasPrefix:@" "])
							{
								line = [line substringFromIndex:1];
							}
						}
						
						[self _processLine:line];
						
						if (needsBR)
						{
							[self _pushTag:@"br" attributes:nil];
							[self _popTag];
						}
					}
					else
					{
						NSLog(@"empty line");
					}
				}
				
				if (hasTwoNL || headerLevel || !shouldOutputLineText)
				{
					// end of paragraph
					[self _popTag];
				}
				
				if (hasTwoNL)
				{
					lineIndex++;
				}
			}
		}
		else
		{
			[scanner scanString:@"\n" intoString:NULL];
		}
		
		lineIndex++;
	}
	
	// pop all remaining open tags
	while ([_tagStack count])
	{
		[self _popTag];
	}
	
	if (_delegateFlags.supportsEndDocument)
	{
		[_delegate parserDidEndDocument:self];
	}
	
	return YES;
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
