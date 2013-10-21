//
//  DTMarkdownParser.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
#import "NSScanner+DTMarkdown.h"


// constants for special lines
NSString * const DTMarkdownParserSpecialTagH1 = @"H1";
NSString * const DTMarkdownParserSpecialTagH2 = @"H2";
NSString * const DTMarkdownParserSpecialTagHR = @"HR";
NSString * const DTMarkdownParserSpecialTagPre = @"PRE";


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
	NSMutableDictionary *_references;
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
	else if ([string hasPrefix:@"~~"])
	{
		return @"~~";
	}
	else if ([string hasPrefix:@"!["])
	{
		return @"![";
	}
	else if ([string hasPrefix:@"["])
	{
		return @"[";
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
	else if ([marker isEqualToString:@"~~"])
	{
		[self _pushTag:@"del" attributes:nil];
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
	
	NSCharacterSet *markerChars = [NSCharacterSet characterSetWithCharactersInString:@"*_~[!"];
	
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
			NSString *effectiveOpeningMarker = [self _effectiveMarkerPrefixOfString:openingMarkers];
			
			NSAssert(effectiveOpeningMarker, @"There should be a closing marker to look for because we only get here from having scanned for marker characters");
			
			
			if ([effectiveOpeningMarker isEqualToString:@"!["] || [effectiveOpeningMarker isEqualToString:@"["])
			{
				NSDictionary *attributes = nil;
				
				if ([scanner scanUpToString:@"]" intoString:&enclosedPart])
				{
					// scan closing part of link
					if ([scanner scanString:@"]" intoString:NULL])
					{
						// skip whitespace
						[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
						
						if ([scanner scanString:@"(" intoString:NULL])
						{
							// has potentially inline address
							
							NSString *hyperlink;
							
							if ([scanner scanUpToString:@")" intoString:&hyperlink])
							{
								// see if it is closed too
								if ([scanner scanString:@")" intoString:NULL])
								{
									NSString *URLString;
									NSString *title;
									
									NSScanner *urlScanner = [NSScanner scannerWithString:hyperlink];
									urlScanner.charactersToBeSkipped = nil;
									
									if ([urlScanner scanMarkdownHyperlink:&URLString title:&title])
									{
										NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
										
										if ([URLString length])
										{
											tmpDict[@"href"] = URLString;
										}
										
										if ([title length])
										{
											tmpDict[@"title"] = title;
										}
										
										if ([tmpDict count])
										{
											attributes = [tmpDict copy];
										}
									}
								}
							}
						}
						else if ([scanner scanString:@"[" intoString:NULL])
						{
							// has potentially address via ref
							
							NSString *reference;
							
							if ([scanner scanUpToString:@"]" intoString:&reference])
							{
								// see if it is closed too
								if ([scanner scanString:@"]" intoString:NULL])
								{
									attributes = _references[[reference lowercaseString]];
								}
							}
							else
							{
								// could be []
								
								if ([scanner scanString:@"]" intoString:NULL])
								{
									reference = [enclosedPart lowercaseString];
									attributes = _references[reference];
								}
							}
						}
					}
				}
				
				// only output hyperlink if all is ok
				if (attributes)
				{
					if ([effectiveOpeningMarker isEqualToString:@"["])
					{
						[self _pushTag:@"a" attributes:attributes];
						[self _reportCharacters:enclosedPart];
						[self _popTag];
					}
					else if ([effectiveOpeningMarker isEqualToString:@"!["])
					{
						NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
						NSString *src = attributes[@"href"];
						
						if (src)
						{
							tmpDict[@"src"] = src;
						}
						
						if ([enclosedPart length])
						{
							tmpDict[@"alt"] = enclosedPart;
						}
						
						NSString *title = attributes[@"title"];
						
						if ([title length])
						{
							// optional title
							tmpDict[@"title"] = title;
						}
						
						[self _pushTag:@"img" attributes:tmpDict];
						[self _popTag];
					}
				}
				else
				{
					// something wrong with this link, just output opening [ and scan after that
					[self _reportCharacters:effectiveOpeningMarker];
					scanner.scanLocation = markedRange.location + [effectiveOpeningMarker length];
				}
				
				continue;
			}
			else if ([scanner scanUpToString:effectiveOpeningMarker intoString:&enclosedPart])
			{
				// there has to be a closing marker as well
				if ([scanner scanString:effectiveOpeningMarker intoString:NULL])
				{
					markedRange.length = scanner.scanLocation - markedRange.location;
					NSString *markedString = [line substringWithRange:markedRange];
					
					[self _processMarkedString:markedString insideMarker:effectiveOpeningMarker];
				}
				else
				{
					// output as is, not enclosed
					NSString *joined = [effectiveOpeningMarker stringByAppendingString:enclosedPart];
					
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
	_references = [NSMutableDictionary new];
	
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	NSUInteger lineIndex = 0;
	while (![scanner isAtEnd])
	{
		NSString *line;
		if ([scanner scanUpToString:@"\n" intoString:&line])
		{
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
							_specialLines[@(lineIndex-1)] = DTMarkdownParserSpecialTagH1;
							didFindSpecial = YES;
						}
						else if (firstChar=='-')
						{
							_specialLines[@(lineIndex-1)] = DTMarkdownParserSpecialTagH2;
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
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagHR;
					didFindSpecial = YES;
				}
			}
			
			// look for lines with references
			if (!didFindSpecial)
			{
				NSString *ref;
				NSString *link;
				NSString *title;
				
				NSScanner *lineScanner = [NSScanner scannerWithString:line];
				lineScanner.charactersToBeSkipped = nil;
				
				if ([lineScanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&link title:&title])
				{
					NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
					
					if (link)
					{
						[tmpDict setObject:link forKey:@"href"];
					}
					
					if (title)
					{
						[tmpDict setObject:title forKey:@"title"];
					}
					
					[_references setObject:tmpDict forKey:ref];
					
					[_ignoredLines addIndex:lineIndex];
					didFindSpecial = YES;
				}
			}
			
			// look for indented pre lines
			if ([line hasPrefix:@"\t" ] || [line hasPrefix:@"    "])
			{
				_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagPre;
				didFindSpecial = YES;
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
			NSString *specialLine = _specialLines[@(lineIndex)];
			BOOL lineIsIgnored = [_ignoredLines containsIndex:lineIndex];

			if ([line hasSuffix:@"\r"])
			{
				// cut off Windows \r
				line = [line substringWithRange:NSMakeRange(0, [line length]-1)];
			}
			
			BOOL hasNL = [scanner scanString:@"\n" intoString:NULL];
			
			lineIndex++;
			
			if (lineIsIgnored)
			{
				continue;
			}
			
			if ([line length])
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
				
				BOOL shouldOutputLineText = YES;
				
				if (specialLine == DTMarkdownParserSpecialTagH1)
				{
					headerLevel = 1;
				}
				else if (specialLine == DTMarkdownParserSpecialTagH2)
				{
					headerLevel = 2;
				}
				else if (specialLine == DTMarkdownParserSpecialTagHR)
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
			// empty line
			[scanner scanString:@"\n" intoString:NULL];
			lineIndex++;
		}
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
