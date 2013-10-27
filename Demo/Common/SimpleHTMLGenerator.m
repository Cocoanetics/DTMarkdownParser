//
//  SimpleHTMLGenerator.m
//  DTMarkdownParser
//
//  Created by Jan on 24.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "SimpleHTMLGenerator.h"


NSString * const kHTMLHeaderFormat = @""
"<!doctype html>\n"
"<head>\n"
"	<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n"

/*"	<link rel=\"stylesheet\" type=\"text/css\" href=\"./Shared/style.css\" charset=\"utf-8\" media=\"all\">\n"*/

"	<style type=\"text/css\">\n"
"	pre, code { background-color: #eee; font-family: Menlo, monospace; }\n"
"	</style>\n"

"	<title>%1$@</title>\n"
"</head>\n"
"<body>\n";

NSString * const kHTMLFooter = @""
"</body>\n"
"</html>\n";


void escapeAndAppend(NSString *string, NSMutableString *HTMLString, BOOL escapeQuotes)
{
	// Parse string for escaping and append piecemeal.
	
	NSUInteger stringLength = string.length;
	
#define ESCAPE_BUFFER_SIZE 64
	NSRange checkedRange = NSMakeRange(0, 0);
	
	NSRange rangeInString = NSMakeRange(0, ESCAPE_BUFFER_SIZE);
	
	while (rangeInString.location < stringLength) {
		unichar buffer[ESCAPE_BUFFER_SIZE];
		
		// Limit character fetching to length of string.
		if (NSMaxRange(rangeInString) > stringLength) {
			rangeInString.length = stringLength - rangeInString.location;
		}
		
		[string getCharacters:buffer
						range:rangeInString];
		
		// Check every character in the buffer for whether it is invalid in HTML text.
		for (NSUInteger i = 0; i < rangeInString.length; i++) {
			unichar c = buffer[i];
			
			NSString *replacementString;
			
			switch  (c) {
				case '<':
					replacementString = @"&lt;";
					break;
					
				case '>':
					replacementString = @"&gt;";
					break;
					
				case '&':
					replacementString = @"&amp;";
					break;
					
				case '"':
					if (escapeQuotes) {
						replacementString = @"&quot;";
					} else {
						replacementString = nil;
					}
					break;
					
				default:
					replacementString = nil;
					checkedRange.length++;
					break;
			}
			
			// Escape if necessary.
			if (replacementString != nil) {
				if (checkedRange.length > 0) {
					[HTMLString appendString:[string substringWithRange:checkedRange]];
				}
				
				[HTMLString appendString:replacementString];
				
				checkedRange.location = i + 1; // Skip over the charcter we just replaced.
				checkedRange.length = 0;
			}
		}
		
		rangeInString.location += ESCAPE_BUFFER_SIZE;
	}
	
	if (checkedRange.length == stringLength) {
		// We went all the way through string without anything to escape.
		[HTMLString appendString:string];
	} else {
		// Append the remainder.
		if (checkedRange.length > 0) {
			[HTMLString appendString:[string substringWithRange:checkedRange]];
		}
	}
}


@implementation SimpleHTMLGenerator {
	NSString *_immediateOpeningTagName;
	
	BOOL _verbose;
}


- (id)init;
{
	self = [super init];
	
	if (self) {
		_HTMLString = [NSMutableString string];
		
		_verbose = NO;
	}
	
	return self;
}

+ (NSSet *)blockLevelElements
{
    static NSSet *blockLevelElementsSet;
    static dispatch_once_t onceToken = 0;
	
    dispatch_once(&onceToken, ^{
		blockLevelElementsSet = [NSSet setWithArray:
								 @[
								   @"p",
								   @"h1", @"h2", @"h3", @"h4", @"h5", @"h6",
								   @"ol", @"ul",
								   @"pre",
								   @"address",
								   @"blockquote",
								   @"dl",
								   @"div",
								   @"fieldset",
								   @"form",
								   @"hr",
								   @"noscript",
								   @"table"
								   ]];
    });

    return blockLevelElementsSet;
}

- (void)parserDidStartDocument:(DTMarkdownParser *)parser;
{
	if (_verbose)  NSLog(@"Markdown Start!");

	_HTMLString = [NSMutableString stringWithFormat:kHTMLHeaderFormat, _title];
}

- (void)parserDidEndDocument:(DTMarkdownParser *)parser;
{
	if (_verbose)  NSLog(@"Markdown End!");

	[_HTMLString appendString:kHTMLFooter];
}

- (void)parser:(DTMarkdownParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
{
	NSUInteger tagStartIndex;
	
	if (_verbose)  tagStartIndex = _HTMLString.length;

	[_HTMLString appendString:@"<"];
	[_HTMLString appendString:elementName];

	[attributeDict enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSString *attribute, BOOL *stop) {
		[_HTMLString appendString:@" "];
		[_HTMLString appendString:attributeName];
		[_HTMLString appendString:@"=\""];
		escapeAndAppend(attribute, _HTMLString, YES);
		[_HTMLString appendString:@"\""];
	}];
	
	[_HTMLString appendString:@">"];
	
	if (_verbose) {
		NSUInteger tagEndIndex = _HTMLString.length;
		NSRange tagRange = NSMakeRange(tagStartIndex, (tagEndIndex - tagStartIndex));
		NSString *elementTag = [_HTMLString substringWithRange:tagRange];
		NSLog(@"%@", elementTag);
	}
	
	_immediateOpeningTagName = elementName;
}

- (void)parser:(DTMarkdownParser *)parser foundCharacters:(NSString *)string;
{
	if (_verbose)  NSLog(@"%@", string);
	
	escapeAndAppend(string, _HTMLString, NO);
	
	_immediateOpeningTagName = nil;
}

- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;
{
	if (_verbose)  NSLog(@"</%@>", elementName);
	
	BOOL isSelfClosingTag = (_immediateOpeningTagName != nil) && [_immediateOpeningTagName isEqualToString:elementName];
	
	if (isSelfClosingTag) {
		// Rewrite the previous tag to be self-closing.
		NSUInteger lastCharacterIndex = _HTMLString.length - 1;
		NSRange closingAngleBracketRange = NSMakeRange(lastCharacterIndex, 1);
		[_HTMLString replaceCharactersInRange:closingAngleBracketRange
								   withString:@" />"];
	}
	else {
		[_HTMLString appendString:@"</"];
		[_HTMLString appendString:elementName];
		[_HTMLString appendString:@">"];
		
		if ([[[self class] blockLevelElements] containsObject:elementName]) {
			[_HTMLString appendString:@"\n\n"];
		}
	}
}

@end
