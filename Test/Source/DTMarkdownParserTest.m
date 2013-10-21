//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
#import "DTInvocationRecorder.h"
#import "DTInvocationTestFunctions.h"
#import "NSInvocation+DTFoundation.h"


@interface DTMarkdownParserTest : SenTestCase

@end

@implementation DTMarkdownParserTest
{
	DTInvocationRecorder *_recorder;
}

- (NSString *)_HTMLFromInvocations
{
	NSMutableString *tmpString = [NSMutableString string];
	
	NSUInteger num = [_recorder.invocations count];
	
	
	for (int i = 0; i<num; i++)
	{
		NSInvocation *oneInvocation = _recorder.invocations[i];
		
		if (oneInvocation.selector == @selector(parser:didStartElement:attributes:))
		{
			NSString *tag = [oneInvocation argumentAtIndexAsObject:3];
			
			BOOL closedRightAway = NO;
			
			if (i<num)
			{
				NSInvocation *nextInvocation = _recorder.invocations[i+1];
				
				if (nextInvocation.selector == @selector(parser:didEndElement:))
				{
					NSString *closedTag = [nextInvocation argumentAtIndexAsObject:3];
					
					if ([tag isEqualToString:closedTag])
					{
						closedRightAway = YES;
						i++;
					}
				}
			}

			NSDictionary *attributes = [oneInvocation argumentAtIndexAsObject:4];
			NSMutableString *attribStr = [NSMutableString string];
			
			if ([attributes count])
			{
				NSArray *sortedKeys = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];
				
				for (NSString *oneKey in sortedKeys)
				{
					NSString *value = attributes[oneKey];
					
					[attribStr appendFormat:@" %@=\"%@\"", oneKey, value];
				}
			}
			
			if (closedRightAway)
			{
				[tmpString appendFormat:@"<%@%@ />", tag, attribStr];
			}
			else
			{
				[tmpString appendFormat:@"<%@%@>", tag, attribStr];
			}

			if ([tag isEqualToString:@"hr"])
			{
				[tmpString appendString:@"\n"];
			}
		}
		else if (oneInvocation.selector == @selector(parser:didEndElement:))
		{
			NSString *tag = [oneInvocation argumentAtIndexAsObject:3];
			
			[tmpString appendFormat:@"</%@>", tag];
			
			if ([tag isEqualToString:@"p"] || [tag isEqualToString:@"hr"] ||[tag hasPrefix:@"h"])
			{
				[tmpString appendString:@"\n"];
			}
		}
		else if (oneInvocation.selector == @selector(parser:foundCharacters:))
		{
			NSString *string = [oneInvocation argumentAtIndexAsObject:3];
			
			[tmpString appendFormat:@"%@", string];
		}
	}
	
	return [tmpString copy];
}

- (void)_logInvocations
{
	for (NSInvocation *invocation in _recorder.invocations)
	{
		NSMutableArray *params = [NSMutableArray array];
		
		for (NSUInteger i=2; i<invocation.methodSignature.numberOfArguments; i++)
		{
			id value = [invocation argumentAtIndexAsObject:i];
			
			if (value)
			{
				[params addObject:[NSString stringWithFormat:@"'%@'", value]];
			}
		}
									
		NSLog(@"%@ %@", NSStringFromSelector(invocation.selector), [params componentsJoinedByString:@", "]);
	}
}

- (DTMarkdownParser *)_parserForString:(NSString *)string options:(DTMarkdownParserOptions)options
{
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:string options:options];
	STAssertNotNil(parser, @"Should be able to create parser");
	
	if (_recorder)
	{
		parser.delegate = (id<DTMarkdownParserDelegate>)_recorder;
	}
	
	return parser;
}

- (DTMarkdownParser *)_parserForFile:(NSString *)file options:(DTMarkdownParserOptions)options
{
	NSString * filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"text"];
	NSString *string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
	
	return [self _parserForString:string options:options];
}

- (NSString *)_resultStringForFile:(NSString *)file
{
	NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
	NSString *rawString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
	
	rawString = [rawString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
	return [rawString stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
}

- (NSPredicate *)_predicateForFindingOpeningTag:(NSString *)tag
{
	return [NSPredicate predicateWithBlock:^BOOL(NSInvocation *invocation, NSDictionary *bindings) {
		
		if (invocation.selector != @selector(parser:didStartElement:attributes:))
		{
			return NO;
		}
		
		NSString *invocationTag = [invocation argumentAtIndexAsObject:3];
		
		return [invocationTag isEqualToString:tag];
	}];
}

- (NSPredicate *)_predicateForFindingClosingTag:(NSString *)tag
{
	return [NSPredicate predicateWithBlock:^BOOL(NSInvocation *invocation, NSDictionary *bindings) {
		
		if (invocation.selector != @selector(parser:didEndElement:))
		{
			return NO;
		}
		
		NSString *invocationTag = [invocation argumentAtIndexAsObject:3];
		
		return [invocationTag isEqualToString:tag];
	}];
}


- (void)setUp
{
    [super setUp];
	
	_recorder = [[DTInvocationRecorder alloc] init];
	[_recorder addProtocol:@protocol(DTMarkdownParserDelegate)];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 
    [super tearDown];
}

- (void)performTest:(SenTestRun *)aRun
{
	// clear recorder before each test
	[_recorder clearLog];
	
	[super performTest:aRun];
}

- (void)testStartDocument
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidStartDocument:), nil);
}

- (void)testEndDocument
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidEndDocument:), nil);
}

- (void)testSimpleLine
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];

	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown");
}

- (void)testMultipleLines
{
	NSString *string = @"Hello Markdown\nA second line\nA third line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A second line\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A third line");
}

- (void)testParagraphBeginEnd
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"p");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"p");
}

- (void)testBlockquote
{
	NSString *string = @"> A Quote\n> With multiple lines\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	// there should be a one blockquote tag
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"blockquote");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"blockquote");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A Quote\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"With multiple lines");
	
	// there should be only a single tag even though there are two \n
	NSArray *tagStarts = [_recorder invocationsMatchingSelector:@selector(parser:didStartElement:attributes:)];
	STAssertTrue([tagStarts count] == 1, @"There should be one tag start");
	
	NSArray *tagEnds = [_recorder invocationsMatchingSelector:@selector(parser:didEndElement:)];
	STAssertTrue([tagEnds count] == 1, @"There should be one tag end");
}

#pragma mark - Emphasis

- (void)testEmphasisAsterisk
{
	NSString *string = @"Normal *Italic Words* *Incomplete\nand * on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"em");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"em");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"em"]];
	STAssertTrue([emStarts count] == 1, @"There should be one tag start");

	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"em"]];
	STAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"*Incomplete\n");
}

- (void)testEmphasisUnderline
{
	NSString *string = @"Normal _Italic Words_ _Incomplete\nand _ on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"em");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"em");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"em"]];
	STAssertTrue([emStarts count] == 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"em"]];
	STAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"_Incomplete\n");
}

- (void)testStrongAsterisk
{
	NSString *string = @"Normal **Strong Words** **Incomplete\nand ** on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"strong");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"strong");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"strong"]];
	STAssertTrue([emStarts count] == 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"strong"]];
	STAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Strong Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"**Incomplete\n");
}

- (void)testStrongUnderline
{
	NSString *string = @"Normal __Strong Words__ __Incomplete\nand __ on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"strong");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"strong");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"strong"]];
	STAssertTrue([emStarts count] == 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"strong"]];
	STAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Strong Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"__Incomplete\n");
}

- (void)testCombinedBoldAndItalics
{
	NSString *string = @"**_Strong Italic Words_**";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><strong><em>Strong Italic Words</em></strong></p>\n";
	NSString *actual = [self _HTMLFromInvocations];

	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMismatchedCombinedBoldAndItalics
{
	NSString *string = @"**_Strong Italic Words**_";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><strong>_Strong Italic Words</strong>_</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStrikethrough
{
	NSString *string = @"~~deleted~~";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><del>deleted</del></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMismatchedStrikethrough
{
	NSString *string = @"~~deleted~";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p>~~deleted~</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}


#pragma mark - Heading

- (void)testHeadingWithHash
{
	NSString *string = @"Normal\n\n# Heading 1\n\n## Heading 2\n\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	// there should be only one h1 starting
	NSArray *h1Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	STAssertTrue([h1Starts count] == 1, @"There should be one H1 start");
	
	// there should be only one h1 closing
	NSArray *h1Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h1"]];
	STAssertTrue([h1Ends count] == 1, @"There should be one H1 end");

	// there should be only one h2 starting
	NSArray *h2Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	STAssertTrue([h2Starts count] == 1, @"There should be one H2 start");
	
	// there should be only one h2 closing
	NSArray *h2Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h2"]];
	STAssertTrue([h2Ends count] == 1, @"There should be one H2 end");

	// look for correct trims
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Normal");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Heading 1");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Heading 2");
}

- (void)testHeadingWithHashClosing
{
	NSString *string = @"# Heading 1 #####\n\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	// there should be only one h1 starting
	NSArray *h1Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	STAssertTrue([h1Starts count] == 1, @"There should be one H1 start");
	
	// there should be only one h1 closing
	NSArray *h1Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h1"]];
	STAssertTrue([h1Ends count] == 1, @"There should be one H1 end");
	
	// look for correct trims
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Heading 1");
}

- (void)testHeadingWithFollowingEquals
{
	NSString *string = @"Heading 1\n=========\n\nNormal";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h1>Heading 1</h1>\n<p>Normal</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
	
	// there should be only one h1 starting
	NSArray *h1Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	STAssertTrue([h1Starts count] == 1, @"There should be one H1 start");
	
	// there should be only one h1 closing
	NSArray *h1Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h1"]];
	STAssertTrue([h1Ends count] == 1, @"There should be one H1 end");
	
	// look for correct trims
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Heading 1");
}


#pragma mark - Line Break

- (void)testGitHubLineBreaks
{
	NSString *string = @"Line1\nLine2\n\nLine3";
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1<br />Line2</p>\n<p>Line3</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testGruberLineBreaks
{
	NSString *string = @"Line1  \nLine2\n\nLine3";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1<br />Line2</p>\n<p>Line3</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHorizontalRule
{
	NSString *string = @"Line1\n\n * * *\n\n - - -\n\nLine2";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1</p>\n<hr />\n<hr />\n<p>Line2</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Links

- (void)testInlineLink
{
	NSString *string = @"Here is [a hyperlink](http://www.cocoanetics.com)";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is <a href=\"http://www.cocoanetics.com\">a hyperlink</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoClosingSquareBracket
{
	NSString *string = @"Here is [not a hyperlink";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is [not a hyperlink</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoClosingRoundBracket
{
	NSString *string = @"Not a [hyperlink](http://foo";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Not a [hyperlink](http://foo</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoRoundBrackets
{
	NSString *string = @"Here is [not a hyperlink] and more text";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is [not a hyperlink] and more text</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}
- (void)testInlineLinkSpacesBetweenSquareAndRoundBracket
{
	NSString *string = @"Here is [a hyperlink]     (http://www.cocoanetics.com)";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is <a href=\"http://www.cocoanetics.com\">a hyperlink</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoRoundBracketsButOtherMarkings
{
	NSString *string = @"Here is [__*not a hyperlink*__] word";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is [<strong><em>not a hyperlink</em></strong>] word</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMultipleSimpleLinksOnMultipleLines
{
	NSString *string = @"Here is [GitHub](http://www.github.com) and [Cocoanetics](http://www.cocoanetics.com).\n\nAnd on new line even [Wikipedia](http://www.wikipedia.org).";

	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is <a href=\"http://www.github.com\">GitHub</a> and <a href=\"http://www.cocoanetics.com\">Cocoanetics</a>.</p>\n<p>And on new line even <a href=\"http://www.wikipedia.org\">Wikipedia</a>.</p>\n";
	
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLink
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkTitleInSingleQuotes
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com 'title'\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\" title=\"title\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkTitleInDoubleQuotes
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com \"title\"\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\" title=\"title\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkTitleInRoundBrackets
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com (title)\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\" title=\"title\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkNonClosed
{
	NSString *string = @"This is a [link with reference][used.\n\n[used]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a [link with reference][used.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkUsingTitleAsRef
{
	NSString *string = @"This is a [Link][].\n\n[link]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\">Link</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkUsingTitleAsRefWithoutMatch
{
	NSString *string = @"This is not a [Link][].\n\n[otherlink]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is not a [Link][].</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkMissingClose
{
	NSString *string = @"This is not a [Link][.\n\n[link]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is not a [Link][.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Images

- (void)testInlineImage
{
	NSString *string = @"![Alt text](/path/to/img.jpg)";

	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><img alt=\"Alt text\" src=\"/path/to/img.jpg\" /></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Test Files

- (void)testEmphasis
{
	DTMarkdownParser *parser = [self _parserForFile:@"emphasis" options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"emphasis"];
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeader
{
	DTMarkdownParser *parser = [self _parserForFile:@"header" options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"header"];
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMissingLinkDefn
{
	DTMarkdownParser *parser = [self _parserForFile:@"missing_link_defn" options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"missing_link_defn"];
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}



@end
