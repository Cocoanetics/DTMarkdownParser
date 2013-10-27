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
		[_HTMLString appendString:attribute];
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

	[_HTMLString appendString:string];
	
	_immediateOpeningTagName = nil;
}

- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;
{
	if (_verbose)  NSLog(@"</%@>", elementName);
	
	BOOL isSelfClosingTag = (_immediateOpeningTagName != nil) && [_immediateOpeningTagName isEqualToString:elementName];
	
	if (isSelfClosingTag) {
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
