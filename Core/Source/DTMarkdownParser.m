//
//  DTMarkdownParser.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
#import "NSScanner+DTMarkdown.h"
#import "DTRangesArray.h"

#import <tgmath.h>

// constants for special lines
NSString * const DTMarkdownParserSpecialTagH1 = @"H1";
NSString * const DTMarkdownParserSpecialTagH2 = @"H2";
NSString * const DTMarkdownParserSpecialTagHeading = @"<HEADING>";
NSString * const DTMarkdownParserSpecialTagHR = @"HR";
NSString * const DTMarkdownParserSpecialTagPre = @"PRE";
NSString * const DTMarkdownParserSpecialFencedPreStart = @"<FENCED BEGIN>";
NSString * const DTMarkdownParserSpecialFencedPreCode = @"<FENCED CODE>";
NSString * const DTMarkdownParserSpecialFencedPreEnd = @"<FENCED END>";
NSString * const DTMarkdownParserSpecialList = @"<LIST>";
NSString * const DTMarkdownParserSpecialSubList = @"<SUBLIST>";
NSString * const DTMarkdownParserSpecialTagBlockquote = @"BLOCKQUOTE";

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
	NSMutableDictionary *_lineIndentLevel;
	DTRangesArray *_lineRanges;
	DTRangesArray *_paragraphRanges;
	
	NSDataDetector *_dataDetector;
}

- (instancetype)initWithString:(NSString *)string options:(DTMarkdownParserOptions)options
{
	self = [super init];
	
	if (self)
	{
		_string = [string copy];
		_options = options;
		
		// default detector
		_dataDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:NULL];
	}
	
	return self;
}

#pragma mark - Communication with Delegate

- (void)_reportBeginOfDocument
{
	if (_delegateFlags.supportsStartDocument)
	{
		[_delegate parserDidStartDocument:self];
	}
}

- (void)_reportEndOfDocument
{
	if (_delegateFlags.supportsEndDocument)
	{
		[_delegate parserDidEndDocument:self];
	}
}

- (void)_reportBeginOfTag:(NSString *)tag attributes:(NSDictionary *)attributes
{
	if (_delegateFlags.supportsStartTag)
	{
		[_delegate parser:self didStartElement:tag attributes:attributes];
	}
}

- (void)_reportEndOfTag:(NSString *)tag
{
	if (_delegateFlags.supportsEndTag)
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

- (NSUInteger)_numberOfLeadingSpacesForLine:(NSString *)line
{
	NSUInteger spacesCount = 0;
	
	for (NSUInteger idx=0; idx < [line length]; idx++)
	{
		unichar ch = [line characterAtIndex:idx];
		
		if (ch == ' ')
		{
			spacesCount++;
		}
		else if (ch == '\t')
		{
			spacesCount+=4;
		}
		else
		{
			break;
		}
	}
	
	return spacesCount;
}

- (void)_setupParsing
{
	_ignoredLines = [NSMutableIndexSet new];
	_specialLines = [NSMutableDictionary new];
	_lineIndentLevel = [NSMutableDictionary new];
	_paragraphRanges = [DTRangesArray new];
	_references = [NSMutableDictionary new];
	
	[self _determineLineRanges];
	[self _findAndHandleReferenceLines];
	[self _findAndMarkSpecialLines];
	[self _fixNewlinesInCodeBlocks];
	
	_tagStack = [NSMutableArray new];
}

- (void)_determineLineRanges
{
	_lineRanges = [DTRangesArray new];
	
	NSRange entireString = NSMakeRange(0, [_string length]);
	[_string enumerateSubstringsInRange:entireString options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		[_lineRanges addRange:enclosingRange];
	}];
}


- (void)_fixNewlinesInCodeBlocks
{
	__block BOOL inFencedBlock = NO;
	
	for (NSUInteger lineIndex=0; lineIndex<[_lineRanges count]; lineIndex++)
	{
		NSString *lineSpecial = _specialLines[@(lineIndex)];
		BOOL lineIsIgnored = [_ignoredLines containsIndex:lineIndex];
		
		if (lineSpecial == DTMarkdownParserSpecialFencedPreStart)
		{
			if (inFencedBlock)
			{
				// incorrect begin, this is an end
				inFencedBlock = NO;
				
				_specialLines[@(lineIndex)] = DTMarkdownParserSpecialFencedPreEnd;
			}
			else
			{
				inFencedBlock = YES;
			}
		}
		else if (lineSpecial == DTMarkdownParserSpecialFencedPreEnd)
		{
			inFencedBlock = NO;
		}
		else if (!lineSpecial)
		{
			if (inFencedBlock)
			{
				if (lineIsIgnored)
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialFencedPreCode;
					[_ignoredLines removeIndex:lineIndex];
				}
				else
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialFencedPreCode;
				}
			}
			else
			{
				NSUInteger indentBefore = lineIndex?[_lineIndentLevel[@(lineIndex-1)] integerValue]:0;
				NSUInteger indentAfter = [_lineIndentLevel[@(lineIndex+1)] integerValue];
				
				if (lineIsIgnored && indentBefore>=4 && indentAfter>=4)
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagPre;
					[_ignoredLines removeIndex:lineIndex];
				}
			}
		}
	};
}


- (void)_findAndMarkSpecialLines
{
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	NSUInteger lineIndex = 0;
	NSInteger previousLineIndent = 0;
	
	NSRange paragraphRange = NSMakeRange(0, 0);
	
	while (![scanner isAtEnd])
	{
		NSString *line;
		
		NSRange lineRange = NSMakeRange(scanner.scanLocation, 0);
		
		if ([scanner scanUpToString:@"\n" intoString:&line] && ![_ignoredLines containsIndex:lineIndex])
		{
			lineRange.length = scanner.scanLocation - lineRange.location;
			paragraphRange = NSUnionRange(paragraphRange, lineRange);
			
			BOOL didFindSpecial = NO;
			NSString *specialOfLineBefore = nil;
			
			NSInteger currentLineIndent = [self _numberOfLeadingSpacesForLine:line];
			_lineIndentLevel[@(lineIndex)] = @(currentLineIndent);
			
			if (lineIndex)
			{
				specialOfLineBefore = _specialLines[@(lineIndex-1)];
				
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
						if (![_ignoredLines containsIndex:lineIndex-1])
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
			}
			
			if (!didFindSpecial)
			{
				NSCharacterSet *ruleCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" -*_\n"];
				
				if ([[line stringByTrimmingCharactersInSet:ruleCharacterSet] length]==0)
				{
					if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] rangeOfString:@"   "].location == NSNotFound)
					{
						_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagHR;
					}
					
					// block it from further special detection
					didFindSpecial = YES;
				}
			}
			
			// look for indented pre lines
			if (!didFindSpecial && ([line hasPrefix:@"\t" ] || [line hasPrefix:@"    "]))
			{
				// PRE only possible if there is an empty line before it or already a PRE, or beginning doc
				
				if (!lineIndex || (lineIndex>0 && (specialOfLineBefore == DTMarkdownParserSpecialTagPre || [_ignoredLines containsIndex:lineIndex-1])))
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagPre;
					didFindSpecial = YES;
				}
			}
			
			if (!didFindSpecial && [line hasPrefix:@"```"])
			{
				if (specialOfLineBefore == DTMarkdownParserSpecialFencedPreCode || specialOfLineBefore == DTMarkdownParserSpecialFencedPreStart)
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialFencedPreEnd;
					[_ignoredLines addIndex:lineIndex];
				}
				else
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialFencedPreStart;
					[_ignoredLines addIndex:lineIndex];
				}
				
				didFindSpecial = YES;
			}
			
			if (!didFindSpecial)
			{
				if (specialOfLineBefore == DTMarkdownParserSpecialFencedPreCode || specialOfLineBefore == DTMarkdownParserSpecialFencedPreStart)
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialFencedPreCode;
				}
			}
			
			if (!didFindSpecial)
			{
				if ([line hasPrefix:@"#"])
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagHeading;
					
					didFindSpecial = YES;
				}
			}
			
			if (!didFindSpecial)
			{
				NSScanner *lineScanner = [NSScanner scannerWithString:line];
				lineScanner.charactersToBeSkipped = nil;
				
				NSString *listPrefix;
			 	if (specialOfLineBefore == DTMarkdownParserSpecialList || specialOfLineBefore == DTMarkdownParserSpecialSubList)
				{
					// line before ist list start
					if ([self _isSubListAtLineIndex:lineIndex])
					{
						NSString *indentedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						
						NSScanner *indentedScanner = [NSScanner scannerWithString:indentedLine];
						indentedScanner.charactersToBeSkipped = nil;
						
						if ([indentedScanner scanMarkdownLineListPrefix:&listPrefix])
						{
							_specialLines[@(lineIndex)] = DTMarkdownParserSpecialSubList;
						}
					}
				}
				else if ([lineScanner scanMarkdownLineListPrefix:&listPrefix])
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialList;
				}
			}
			
			if (!didFindSpecial)
			{
				if ([line hasPrefix:@">"])
				{
					_specialLines[@(lineIndex)] = DTMarkdownParserSpecialTagBlockquote;
					didFindSpecial = YES;
				}
			}
			
			previousLineIndent = currentLineIndent;
		}
		
		// look for empty lines
		if (![[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		{
			[_ignoredLines addIndex:lineIndex];
		}
		
		if ([scanner scanString:@"\n" intoString:NULL])
		{
			lineRange.length++;
		}
		
		paragraphRange = NSUnionRange(paragraphRange, lineRange);
		
		BOOL currentLineIsIgnored = [_ignoredLines containsIndex:lineIndex];
		BOOL currentLineIsHR = _specialLines[@(lineIndex)] == DTMarkdownParserSpecialTagHR || _specialLines[@(lineIndex)] == DTMarkdownParserSpecialTagHeading;
		BOOL currentLineBeginsList = (_specialLines[@(lineIndex)] == DTMarkdownParserSpecialList) || (_specialLines[@(lineIndex)] == DTMarkdownParserSpecialSubList);
		
		if (currentLineIsIgnored || [scanner isAtEnd] || currentLineIsHR || currentLineBeginsList)
		{
			NSRange netParagraphRange = paragraphRange;
			
			if (currentLineIsIgnored || currentLineIsHR || currentLineBeginsList)
			{
				netParagraphRange.length -= lineRange.length;
			}
			
			if (netParagraphRange.length)
			{
				[_paragraphRanges addRange:netParagraphRange];
			}
			
			if (currentLineIsIgnored || currentLineIsHR)
			{
				[_paragraphRanges addRange:lineRange];
				paragraphRange = NSMakeRange(paragraphRange.location + paragraphRange.length, 0);
			}
			else
			{
				paragraphRange = lineRange;
			}
		}
		
		lineIndex++;
	}
}

- (void)_findAndHandleReferenceLines
{
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	[_lineRanges enumerateLineRangesUsingBlock:^(NSRange range, NSUInteger idx, BOOL *stop) {
		
		if ([_ignoredLines containsIndex:idx])
		{
			return;
		}
		
		scanner.scanLocation = range.location;
		
		NSString *ref;
		NSString *link;
		NSString *title;
		
		if ([scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&link title:&title])
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
			
			[_ignoredLines addIndex:idx];
			
			if (scanner.scanLocation>NSMaxRange(range))
			{
				[_ignoredLines addIndex:idx+1];
			}
		}
	}];
}

- (BOOL)_hasHangingParagraphsForListItemBeginningAtLineIndex:(NSUInteger)lineIndex
{
	NSRange lineRange;
	NSUInteger numberOfLines = [_lineRanges count];
	NSUInteger numberIgnored = 0;
	
	while (lineIndex<(numberOfLines-1))
	{
		lineIndex++;
		
		if ([_ignoredLines containsIndex:lineIndex])
		{
			numberIgnored ++;
			continue;
		}
		
		// only normal paragraphs can be hanging
		if (_specialLines[@(lineIndex)])
		{
			return NO;
		}
		
		lineRange = [_lineRanges rangeAtIndex:lineIndex];
		NSString *line = [_string substringWithRange:lineRange];
		
		NSUInteger leadingSpaces = [self _numberOfLeadingSpacesForLine:line];
		
		if (leadingSpaces>0 && numberIgnored>0)
		{
			return YES;
		}
		
		return NO;
	}
	
	return NO;
}


- (NSUInteger)_lineIndexOfListItemBeforeLineIndex:(NSUInteger)lineIndex
{
	BOOL foundPreviousListItem = NO;
	
	while (lineIndex>0)
	{
		lineIndex--;
		
		NSString *lineSpecial = _specialLines[@(lineIndex)];
		
		if (lineSpecial == DTMarkdownParserSpecialSubList || lineSpecial == DTMarkdownParserSpecialList)
		{
			foundPreviousListItem = YES;
			break;
		}
	}
	
	NSAssert(foundPreviousListItem, @"Error, you called %s without there being a previous list item", __PRETTY_FUNCTION__);
	
	return lineIndex;
}

- (NSUInteger)_lineIndexOfListHeadBeforeLineIndex:(NSUInteger)lineIndex
{
	BOOL foundPreviousListItem = NO;
	
	while (lineIndex>0)
	{
		lineIndex--;
		
		NSString *lineSpecial = _specialLines[@(lineIndex)];
		
		if (lineSpecial == DTMarkdownParserSpecialList)
		{
			foundPreviousListItem = YES;
			break;
		}
	}
	
	NSAssert(foundPreviousListItem, @"Error, you called %s without there being a previous list item", __PRETTY_FUNCTION__);
	
	return lineIndex;
}

- (BOOL)_isSubListAtLineIndex:(NSUInteger)lineIndex
{
	NSString *lineSpecial = _specialLines[@(lineIndex)];
	
	NSInteger indexOfListStartLine = lineIndex;
	
	while (indexOfListStartLine>0)
	{
		indexOfListStartLine--;
		
		lineSpecial = _specialLines[@(indexOfListStartLine)];
		
		if (lineSpecial == DTMarkdownParserSpecialList)
		{
			break;
		}
	}
	
	NSAssert(indexOfListStartLine >= 0, @"Missing list start for sub list");
	
	NSInteger indexOfPreviousSubList = lineIndex;
	BOOL hasPreviousSubList = NO;
	
	while (indexOfPreviousSubList>0)
	{
		indexOfPreviousSubList--;
		
		lineSpecial = _specialLines[@(indexOfPreviousSubList)];
		
		if (lineSpecial == DTMarkdownParserSpecialSubList)
		{
			hasPreviousSubList = YES;
			break;
		}
	}
	
	NSUInteger spacesLine = [_lineIndentLevel[@(lineIndex)] integerValue];
	
	// direct line after list start
	if (!hasPreviousSubList)
	{
		if (spacesLine<=7)
		{
			return YES;
		}
	}
	else
	{
		NSUInteger spacesLineBefore = [_lineIndentLevel[@(indexOfPreviousSubList)] integerValue];
		
		NSUInteger listLevelBefore = (NSUInteger)ceil(spacesLineBefore/4.0);
		NSUInteger listLevel = (NSUInteger)ceil(spacesLine/4.0);
		
		if (listLevel>listLevelBefore)
		{
			if (listLevel-listLevelBefore<=1)
			{
				return YES;
			}
		}
		else
		{
			// less indentation always allowed
			return YES;
		}
	}
	
	return NO;
}

- (NSUInteger)_listLevelForLineAtIndex:(NSUInteger)lineIndex
{
	NSString *lineSpecial = _specialLines[@(lineIndex)];
	
	NSAssert(lineSpecial == DTMarkdownParserSpecialSubList || lineSpecial == DTMarkdownParserSpecialList, @"%s only valid for list and sublist items", __PRETTY_FUNCTION__);
	
	// main list is always level 1
	if (lineSpecial == DTMarkdownParserSpecialList)
	{
		return 1;
	}
	
	NSUInteger spaces = [_lineIndentLevel[@(lineIndex)] integerValue];
	NSUInteger previousListItem = [self _lineIndexOfListItemBeforeLineIndex:lineIndex];
	NSString *previousListItemSpecial = _specialLines[@(previousListItem)];
	
	if (previousListItemSpecial == DTMarkdownParserSpecialList)
	{
		// this is the first subitem
		
		NSUInteger listHeadSpaces = [_lineIndentLevel[@(previousListItem)] integerValue];
		
		if (spaces==listHeadSpaces)
		{
			return 1;
		}
		else
		{
			return 2;
		}
	}
	else
	{
		NSUInteger previousItemSpaces = [_lineIndentLevel[@(previousListItem)] integerValue];
		
		NSUInteger previousItemLevel = [self _listLevelForLineAtIndex:previousListItem];
		
		if (spaces == previousItemSpaces)
		{
			return previousItemLevel;
		}
		
		NSUInteger listHead = [self _lineIndexOfListHeadBeforeLineIndex:lineIndex];
		NSUInteger headSpaces = [_lineIndentLevel[@(listHead)] integerValue];
		
		if (spaces<headSpaces)
		{
			return previousItemLevel + 1;
		}
		else if (spaces == headSpaces)
		{
			return 1;
		}
		
		return (NSUInteger)ceilf(spaces/4.0) + 1;
	}
}


#pragma mark - Parsing

// process the text between the [] of a hyperlink, this is similar to the parse loop, but with several key differences
- (void)_processHyperlinkEnclosedText:(NSString *)text allowAutoDetection:(BOOL)allowAutoDetection
{
	NSScanner *scanner = [NSScanner scannerWithString:text];
	scanner.charactersToBeSkipped = nil;
	
	NSCharacterSet *specialChars = [NSCharacterSet characterSetWithCharactersInString:@"*_~[!`<"];
	
	while (![scanner isAtEnd])
	{
		NSString *part;
		NSUInteger positionBeforeScan = scanner.scanLocation;
		
		// scan part until next special character
		if ([scanner scanUpToCharactersFromSet:specialChars intoString:&part])
		{
			// output part before markers
			[self _processCharacters:part inRange:NSMakeRange(positionBeforeScan, positionBeforeScan-scanner.scanLocation) allowAutodetection:allowAutoDetection];
			
			// re-enable detection, this might have been a faulty string containing a href
			allowAutoDetection = YES;
		}
		
		// stop scanning if done
		if ([scanner isAtEnd])
		{
			break;
		}
		
		// scan marker
		NSString *effectiveOpeningMarker;
		NSDictionary *linkAttributes;
		positionBeforeScan = scanner.scanLocation;
		
		if ([scanner scanMarkdownImageAttributes:&linkAttributes references:_references])
		{
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			[self _handleImageAttributes:linkAttributes inRange:range];
			
			continue;
		}
		
		if ([scanner scanMarkdownTextBetweenFormatMarkers:&part outermostMarker:&effectiveOpeningMarker])
		{
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			[self _handleMarkedText:part marker:effectiveOpeningMarker inRange:range];
			
			continue;
		}
		
		// single special character, just output
		NSRange range = NSMakeRange(scanner.scanLocation, 1);
		NSString *specialChar = [scanner.string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
		scanner.scanLocation ++;
		
		[self _handleText:specialChar inRange:range allowAutodetection:NO];
	}
}

// process characters and optionally auto-detect links
- (void)_processCharacters:(NSString *)string inRange:(NSRange)range allowAutodetection:(BOOL)allowAutodetection
{
	if (!allowAutodetection || !_dataDetector)
	{
		[self _reportCharacters:string];
		return;
	}
	
	NSArray *matches = [_dataDetector matchesInString:string options:0 range:NSMakeRange(0, [string length])];
	
	NSUInteger outputChars = 0;
	
	for (NSTextCheckingResult *match in matches)
	{
		if (match.range.location > outputChars)
		{
			// need to output part before match
			NSString *substring = [string substringWithRange:NSMakeRange(outputChars, match.range.location - outputChars)];
			[self _reportCharacters:substring];
		}
		
		NSString *urlString = [string substringWithRange:match.range];
		
		// get URL from match if possible
		NSURL *URL = [match URL];
		
#if TARGET_OS_IPHONE
		if ([[URL scheme] isEqualToString:@"tel"])
		{
			// output as is
			NSString *substring = [string substringWithRange:match.range];
			[self _reportCharacters:substring];
		}
		else
#endif
		{
			NSDictionary *attributes = @{@"href": [URL absoluteString]};
			[self _pushTag:@"a" attributes:attributes];
			[self _reportCharacters:urlString];
			[self _popTag];
		}
		
		outputChars = NSMaxRange(match.range);
	}
	
	// output reset after last hyperlink
	NSRange restRange = NSMakeRange(outputChars, [string length] - outputChars);
	
	if (restRange.length>0)
	{
		// need to output part before match
		NSString *substring = [string substringWithRange:restRange];
		[self _reportCharacters:substring];
	}
}

// text without format markers, but possibly with link inside
- (void)_handleText:(NSString *)text inRange:(NSRange)range  allowAutodetection:(BOOL)allowAutodetection
{
	if ([text rangeOfString:@"["].location == NSNotFound)
	{
		// shortcut if text contains no hyperlink
		[self _processCharacters:text inRange:range allowAutodetection:allowAutodetection];
	}
	else
	{
		NSScanner *subScanner = [NSScanner scannerWithString:text];
		subScanner.charactersToBeSkipped = nil;
		
		NSUInteger positionBeforeScan;
		
		while (![subScanner isAtEnd])
		{
			NSString *substring;
			
			positionBeforeScan = subScanner.scanLocation;
			
			if ([subScanner scanUpToString:@"[" intoString:&substring])
			{
				// part before a link
				NSRange substringRange = NSMakeRange(range.location, [substring length]);
				
				[self _processCharacters:substring inRange:substringRange allowAutodetection:allowAutodetection];
			}
			
			NSDictionary *linkAttributes;
			NSString *enclosedString;
			positionBeforeScan = subScanner.scanLocation;
			
			if ([subScanner scanMarkdownHyperlinkAttributes:&linkAttributes enclosedString:&enclosedString references:_references])
			{
				NSRange subRange = NSMakeRange(positionBeforeScan, subScanner.scanLocation - positionBeforeScan);
				[self _handleLinkText:enclosedString attributes:linkAttributes inRange:subRange];
				
				continue;
			}
			else
			{
				if ([subScanner scanString:@"[" intoString:NULL])
				{
					NSRange subRange = NSMakeRange(positionBeforeScan, 1);
					[self _processCharacters:@"[" inRange:subRange allowAutodetection:NO];
				}
			}
		}
	}
}

// process text with the additional info that we are at the beginning of a line
- (void)_handleTextAtBeginningOfLine:(NSString *)text inRange:(NSRange)range lineIndex:(NSUInteger)lineIndex
{
	// white space is always trimmed off at beginning of line
	BOOL hasIndent = NO;
	
	while ([text hasPrefix:@" "])
	{
		text = [text substringFromIndex:1];
		hasIndent = YES;
	}
	
	NSRange lineRange = [_lineRanges rangeContainingLocation:range.location];
	NSRange paragraphRange = [_paragraphRanges rangeContainingLocation:range.location];
	
	BOOL isAtBeginOfParagraph = paragraphRange.location == lineRange.location;
	
	if (lineIndex)
	{
		NSString *specialCurrentLine = _specialLines[@(lineIndex)];
		NSString *specialPreviousLine = _specialLines[@(lineIndex-1)];
		
		if (!specialPreviousLine && isAtBeginOfParagraph && !specialCurrentLine)
		{
			
			// a new normal paragraph without indentation terminates previous list
			if (!hasIndent)
			{
				if ([_tagStack containsObject:@"li"])
				{
					[self _closeAllIfNecessary];
				}
			}
			
			if (![_tagStack containsObject:@"p"])
			{
				[self _pushTag:@"p" attributes:nil];
			}
		}
	}
	
	[self _handleText:text inRange:range allowAutodetection:YES];
}

// text enclosed in formatting markers
- (void)_handleMarkedText:(NSString *)markedText marker:(NSString *)marker inRange:(NSRange)range
{
	BOOL processFurtherMarkers = YES;
	BOOL allowAutodetection = YES;
	
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
	else if ([marker isEqualToString:@"`"])
	{
		[self _pushTag:@"code" attributes:nil];
		processFurtherMarkers = NO;
		allowAutodetection = NO;
	}
	
	if (processFurtherMarkers)
	{
		NSScanner *scanner = [NSScanner scannerWithString:markedText];
		scanner.charactersToBeSkipped = nil;
		
		NSString *furtherMarkedText;
		NSString *furtherMarker;
		
		NSUInteger markerLength = [marker length];
		NSRange furtherRange = NSMakeRange(range.location + markerLength, range.length - 2*markerLength);
		
		if ([scanner scanMarkdownTextBetweenFormatMarkers:&furtherMarkedText outermostMarker:&furtherMarker])
		{
			[self _handleMarkedText:furtherMarkedText marker:furtherMarker inRange:furtherRange];
		}
		else
		{
			[self _handleText:markedText inRange:range allowAutodetection:allowAutodetection];
		}
	}
	else
	{
		[self _handleText:markedText inRange:range allowAutodetection:allowAutodetection];
	}
	
	// close the tag for this marker
	[self _popTag];
}

// image
- (void)_handleImageAttributes:(NSDictionary *)attributes inRange:(NSRange)range
{
	[self _pushTag:@"img" attributes:attributes];
	[self _popTag];
}

// hyperlink
- (void)_handleLinkText:(NSString *)linkText attributes:(NSDictionary *)attributes inRange:(NSRange)range
{
	[self _pushTag:@"a" attributes:attributes];
	
	// might contain further markdown/images
	[self _processHyperlinkEnclosedText:linkText allowAutoDetection:NO];
	
	[self _popTag];
}

// code blocks
- (void)_handlePreformattedLine:(NSString *)line inRange:(NSRange)range lineIndex:(NSUInteger)lineIndex
{
	NSString *codeLine;
	NSString *lineSpecial = _specialLines[@(lineIndex)];
	
	if (lineSpecial == DTMarkdownParserSpecialTagPre)
	{
		// trim off indenting
		if ([line hasPrefix:@"\t"])
		{
			codeLine = [line substringFromIndex:1];
		}
		else if ([line hasPrefix:@"    "])
		{
			codeLine = [line substringFromIndex:4];
		}
		else
		{
			codeLine = line;
		}
	}
	else
	{
		codeLine = line;
	}
	
	if (![[self _currentTag] isEqualToString:@"code"])
	{
		[self _pushTag:@"pre" attributes:nil];
		[self _pushTag:@"code" attributes:nil];
	}
	
	[self _reportCharacters:codeLine];
	
	NSString *followingLineSpecial = _specialLines[@(lineIndex+1)];
	
	if (!followingLineSpecial || [_ignoredLines containsIndex:lineIndex+1])
	{
		[self _popTag];
		[self _popTag];
	}
}

// header lines
- (void)_handleHeader:(NSString *)header inRange:(NSRange)range lineIndex:(NSUInteger)lineIndex
{
	NSString *lineSpecial = _specialLines[@(lineIndex)];
	NSUInteger headerLevel = 0;
	
	while ([header hasPrefix:@"#"])
	{
		headerLevel++;
		
		header = [header substringFromIndex:1];
	}
	
	// trim off leading spaces
	while ([header hasPrefix:@" "])
	{
		header = [header substringFromIndex:1];
	}
	
	// trim off trailing hashes
	while ([header hasSuffix:@"#"] || [header hasSuffix:@"#\n"])
	{
		header = [header substringToIndex:[header length]-1];
	}
	
	// trim off trailing spaces
	while ([header hasSuffix:@" "])
	{
		header = [header substringToIndex:[header length]-1];
	}
	
	if (lineSpecial == DTMarkdownParserSpecialTagH1)
	{
		headerLevel = 1;
	}
	else if (lineSpecial == DTMarkdownParserSpecialTagH2)
	{
		headerLevel = 2;
	}
	
	NSAssert(headerLevel, @"There should always be a header level here");
	
	NSString *tag = [NSString stringWithFormat:@"h%d", (int)headerLevel];
	
	[self _pushTag:tag attributes:nil];
	
	[self _processCharacters:header inRange:range allowAutodetection:YES];
	
	[self _popTag];
}

// horizontal rule
- (void)_handleHorizontalRuleInRange:(NSRange)range
{
	[self _pushTag:@"hr" attributes:nil];
	[self _popTag];
}

// line break
- (void)_handleLineBreakinRange:(NSRange)range
{
	[self _pushTag:@"br" attributes:nil];
	[self _popTag];
}

- (void)_handleBlockquoteLine:(NSString *)line inRange:(NSRange)lineRange
{
	NSAssert([line hasPrefix:@">"], @"line should have >");
	
	// blockquote
	line = [line substringFromIndex:1];
	
	if ([line hasPrefix:@" "])
	{
		line = [line substringFromIndex:1];
	}
	
	if (![_tagStack containsObject:@"blockquote"])
	{
		[self _pushTag:@"blockquote" attributes:nil];
		
		[self _pushTag:@"p" attributes:nil];
	}
	
	[self _handleText:line inRange:lineRange allowAutodetection:YES];
}

- (void)_handleListItemPrefix:(NSString *)prefix inRange:(NSRange)range lineIndex:(NSUInteger)lineIndex
{
	NSString *specialTypeOfLine = _specialLines[@(lineIndex)];
	BOOL needOpenNewListLevel = NO;
	NSUInteger currentLineIndent = 0;
	NSUInteger previousLineIndent = 0;
	
	if (specialTypeOfLine == DTMarkdownParserSpecialSubList)
	{
		NSUInteger prevousListItem = [self _lineIndexOfListItemBeforeLineIndex:lineIndex];
		
		currentLineIndent = [self _listLevelForLineAtIndex:lineIndex];
		previousLineIndent = [self _listLevelForLineAtIndex:prevousListItem];
		
		if (currentLineIndent > previousLineIndent)
		{
			needOpenNewListLevel = YES;
		}
	}
	else if (specialTypeOfLine == DTMarkdownParserSpecialList)
	{
		// close all lists this is a new one
		while ([_tagStack containsObject:@"ul"] || [_tagStack containsObject:@"ol"])
		{
			[self _popTag];
		}
	}
	
	NSAssert(![[self _currentTag] isEqualToString:@"p"], @"There should never be an open P tag in %s", __PRETTY_FUNCTION__);
	
	if (specialTypeOfLine == DTMarkdownParserSpecialList)
	{
		if (![_tagStack containsObject:@"ul"] && ![_tagStack containsObject:@"ol"])
		{
			// first line of list opens only if no list present
			needOpenNewListLevel = YES;
		}
	}
	
	if (currentLineIndent<previousLineIndent)
	{
		NSInteger level = previousLineIndent;
		
		// close any number of list levels
		while (level>currentLineIndent)
		{
			NSString *tagToPop = [self _currentTag];
			
			[self _popTag];
			
			if ([tagToPop isEqualToString:@"ul"] || [tagToPop isEqualToString:@"ol"])
			{
				level--;
			}
		}
	}
	
	if (needOpenNewListLevel)
	{
		// need to open list
		if ([prefix hasSuffix:@"."])
		{
			// ordered list
			[self _pushTag:@"ol" attributes:nil];
		}
		else
		{
			// unordered list
			[self _pushTag:@"ul" attributes:nil];
		}
	}
	
	if ([[self _currentTag] isEqualToString:@"li"])
	{
		[self _popTag]; // previous li
	}
	
	[self _pushTag:@"li" attributes:nil];
	
	BOOL hasHangingParagraphs = [self _hasHangingParagraphsForListItemBeginningAtLineIndex:lineIndex];
	
	if (hasHangingParagraphs)
	{
		[self _pushTag:@"p" attributes:nil];
	}
}

- (void)_closeBlockIfNecessary
{
	while ([_tagStack containsObject:@"p"])
	{
		[self _popTag];
	}
}

- (void)_closeAllIfNecessary
{
	while ([_tagStack count])
	{
		[self _popTag];
	}
}

- (void)_parseLoop
{
	NSScanner *scanner = [NSScanner scannerWithString:_string];
	scanner.charactersToBeSkipped = nil;
	
	NSCharacterSet *specialChars = [NSCharacterSet characterSetWithCharactersInString:@"*_~[!`<\n"];
	
	NSUInteger positionBeforeScan;
	
	while (![scanner isAtEnd])
	{
		NSString *partWithoutSpecialChars;
		positionBeforeScan = scanner.scanLocation;
		NSRange lineBreakRange = NSMakeRange(scanner.scanLocation, 0);
		
		NSUInteger lineIndex = [_lineRanges indexOfRangeContainingLocation:positionBeforeScan];
		NSRange lineRange = [_lineRanges rangeContainingLocation:positionBeforeScan];
		BOOL isAtBeginningOfLine = (lineRange.location == positionBeforeScan);
		
		NSRange paragraphRange = [_paragraphRanges rangeContainingLocation:positionBeforeScan];
		BOOL isAtEndOfParagraph = (NSMaxRange(lineRange) == NSMaxRange(paragraphRange));
		
		if (isAtBeginningOfLine)
		{
			
			NSString *lineSpecial = _specialLines[@(lineIndex)];
			BOOL lineIsIgnored = [_ignoredLines containsIndex:lineIndex];
			
			if (lineSpecial == DTMarkdownParserSpecialSubList || lineSpecial == DTMarkdownParserSpecialList)
			{
				// skip the spaces
				
				[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
				
				NSString *prefix;
				
				if ([scanner scanMarkdownLineListPrefix:&prefix])
				{
					[self _handleListItemPrefix:prefix inRange:NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan) lineIndex:lineIndex];
				}
				
				continue;
			}
			
			if (!lineSpecial && !lineIsIgnored)
			{
				if (![_tagStack containsObject:@"p"] && ![_tagStack containsObject:@"li"])
				{
					[self _pushTag:@"p" attributes:nil];
				}
			}
			
			if (lineSpecial || lineIsIgnored)
			{
				NSString *line = @"";
				
				// scan entire line
				[scanner scanUpToString:@"\n" intoString:&line];
				
				// trim off Windows newline
				if ([line hasSuffix:@"\r"])
				{
					line = [line substringToIndex:[line length]-1];
				}
				
				if ([scanner scanString:@"\n" intoString:NULL])
				{
					if (!isAtEndOfParagraph || lineSpecial == DTMarkdownParserSpecialTagPre || lineSpecial == DTMarkdownParserSpecialFencedPreCode)
					{
						line = [line stringByAppendingString:@"\n"];
					}
				}
				
				if (lineIsIgnored)
				{
					// empty line, terminates a multi-P in LI
					
					while ([_tagStack containsObject:@"p"])
					{
						[self _popTag];
					}
					
					continue;
				}
				
				if (lineSpecial == DTMarkdownParserSpecialTagHR)
				{
					if (![line hasPrefix:@" "])
					{
						[self _closeAllIfNecessary];
					}
					
					[self _handleHorizontalRuleInRange:lineRange];
					
					continue;
				}
				
				if (lineSpecial == DTMarkdownParserSpecialTagPre || lineSpecial == DTMarkdownParserSpecialFencedPreCode)
				{
					[self _handlePreformattedLine:line inRange:lineRange lineIndex:lineIndex];
					
					continue;
				}
				
				if (lineSpecial == DTMarkdownParserSpecialTagHeading || lineSpecial == DTMarkdownParserSpecialTagH1 || lineSpecial == DTMarkdownParserSpecialTagH2)
				{
					if (![line hasPrefix:@" "])
					{
						[self _closeAllIfNecessary];
					}
					
					[self _handleHeader:line inRange:lineRange lineIndex:lineIndex];
					
					continue;
				}
				
				// DTMarkdownParserSpecialTagBlockquote
				[self _handleBlockquoteLine:line inRange:lineRange];
				
				continue;
			}
		}
		
		if ([scanner scanUpToCharactersFromSet:specialChars intoString:&partWithoutSpecialChars])
		{
			// remove Windows newline character
			if ([partWithoutSpecialChars hasSuffix:@"\r"])
			{
				partWithoutSpecialChars = [partWithoutSpecialChars substringToIndex:[partWithoutSpecialChars length]-1];
			}
			
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			
			lineBreakRange.location = scanner.scanLocation;
			
			if ([scanner scanString:@"\n" intoString:NULL])
			{
				// part has newline
				if (_options && DTMarkdownParserOptionGitHubLineBreaks)
				{
					lineBreakRange.length = 1;
				}
				else
				{
					if ([partWithoutSpecialChars hasSuffix:@"  "])
					{
						partWithoutSpecialChars = [partWithoutSpecialChars substringToIndex:[partWithoutSpecialChars length]-2];
						
						// range includes the two spaces
						lineBreakRange.location = scanner.scanLocation-3;
						lineBreakRange.length = 3;
					}
					else
					{
						if (isAtEndOfParagraph)
						{
							// triggers closing of paragraph
							lineBreakRange.length = 1;
						}
						else
						{
							// just extend range to include \n
							range.length++;
							partWithoutSpecialChars = [partWithoutSpecialChars stringByAppendingString:@"\n"];
						}
					}
				}
			}
			
			if (isAtBeginningOfLine)
			{
				[self _handleTextAtBeginningOfLine:partWithoutSpecialChars inRange:range lineIndex:lineIndex];
			}
			else
			{
				[self _handleText:partWithoutSpecialChars inRange:range allowAutodetection:YES];
			}
			
			if (lineBreakRange.length)
			{
				if (isAtEndOfParagraph)
				{
					[self _closeBlockIfNecessary];
				}
				else
				{
					[self _handleLineBreakinRange:lineBreakRange];
				}
			}
			
			continue;
		}
		
		if ([scanner scanString:@"\n" intoString:NULL])
		{
			// end of line
			continue;
		}
		
		NSDictionary *linkAttributes;
		NSString *enclosedString;
		positionBeforeScan = scanner.scanLocation;
		
		if ([scanner scanMarkdownImageAttributes:&linkAttributes references:_references])
		{
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			[self _handleImageAttributes:linkAttributes inRange:range];
			
			continue;
		}
		
		if ([scanner scanMarkdownHyperlinkAttributes:&linkAttributes enclosedString:&enclosedString references:_references])
		{
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			[self _handleLinkText:enclosedString attributes:linkAttributes inRange:range];
			
			continue;
		}
		
		NSString *effectiveOpeningMarker;
		
		if ([scanner scanMarkdownTextBetweenFormatMarkers:&enclosedString outermostMarker:&effectiveOpeningMarker])
		{
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			[self _handleMarkedText:enclosedString marker:effectiveOpeningMarker inRange:range];
			
			continue;
		}
		
		// single special character, just output
		NSRange range = NSMakeRange(scanner.scanLocation, 1);
		NSString *specialChar = [scanner.string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
		scanner.scanLocation ++;
		
		[self _handleText:specialChar inRange:range allowAutodetection:NO];
		
		positionBeforeScan = scanner.scanLocation;
		
		if ([specialChar isEqualToString:@"["] && [scanner scanUpToCharactersFromSet:specialChars intoString:&partWithoutSpecialChars])
		{
			NSRange range = NSMakeRange(positionBeforeScan, scanner.scanLocation - positionBeforeScan);
			[self _handleText:partWithoutSpecialChars inRange:range allowAutodetection:NO];
		}
	}
	
	[self _closeAllIfNecessary];
}

- (BOOL)parse
{
	if (![_string length])
	{
		return NO;
	}
	
	[self _reportBeginOfDocument];
	
	[self _setupParsing];
	[self _parseLoop];
	
	[self _reportEndOfDocument];
	
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
