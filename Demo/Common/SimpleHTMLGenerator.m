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
"	<title>%1$@</title>\n"
"</head>\n"
"<body>\n";

NSString * const kHTMLFooter = @""
"</body>\n"
"</html>\n";


@implementation SimpleHTMLGenerator {
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

- (void)parser:(DTMarkdownParser *)parser foundCharacters:(NSString *)string;
{
	if (_verbose)  NSLog(@"%@", string);

	[_HTMLString appendString:string];
}

- (void)parser:(DTMarkdownParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
{
	NSMutableString *elementTag = [NSMutableString string];
	[elementTag appendString:@"<"];
	[elementTag appendString:elementName];

	[attributeDict enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSString *attribute, BOOL *stop) {
		[elementTag appendString:@" "];
		[elementTag appendString:attributeName];
		[elementTag appendString:@"=\""];
		[elementTag appendString:attribute];
		[elementTag appendString:@"\""];
	}];
	
	[elementTag appendString:@">"];
	
	if (_verbose)  NSLog(@"%@", elementTag);
	
	// FIXME: Add attributes.
	[_HTMLString appendString:elementTag];
}

- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;
{
	NSMutableString *elementTag = [NSMutableString stringWithFormat:@"</%@>", elementName];
	
	if ([[[self class] blockLevelElements] containsObject:elementName]) {
		[elementTag appendString:@"\n"];
	}
	
	if (_verbose)  NSLog(@"%@", elementTag);
	
	[_HTMLString appendString:elementTag];
}

@end