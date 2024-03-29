//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@import XCTest;
@import DTMarkdownParser;

#import "DTInvocationRecorder.h"
#import "DTInvocationTestFunctions.h"
#import "NSInvocation+DTFoundation.h"
#import "NSString+DTMarkdown.h"


@interface DTMarkdownParserTest : XCTestCase

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
			
			if ([tag isEqualToString:@"p"] || [tag isEqualToString:@"hr"] ||[tag hasPrefix:@"h"]||[tag hasPrefix:@"pre"])
			{
				[tmpString appendString:@"\n"];
			}
		}
		else if (oneInvocation.selector == @selector(parser:foundCharacters:))
		{
			NSString *string = [oneInvocation argumentAtIndexAsObject:3];
			
			[tmpString appendFormat:@"%@", [string stringByAddingHTMLEntities]];
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
	NSLog(@"%@", string);
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:string options:options];
	XCTAssertNotNil(parser, @"Should be able to create parser");
	
	if (_recorder)
	{
		parser.delegate = (id<DTMarkdownParserDelegate>)_recorder;
	}
	
	return parser;
}

- (DTMarkdownParser *)_parserForFile:(NSString *)file options:(DTMarkdownParserOptions)options
{
	NSString *filePath = [self pathForTestResource:file ofType:@"text"];
	NSString *string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
	
	NSLog(@"input: %@", string);

	
	return [self _parserForString:string options:options];
}

- (NSString *)pathForTestResource:(nullable NSString *)name ofType:(nullable NSString *)ext
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];

#if SWIFT_PACKAGE
	NSURL *url = [[[testBundle bundleURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"DTFoundation_DTFoundationTests.bundle"];
	NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
	NSString *finalPath = [resourceBundle pathForResource:name ofType:ext];
#else
	NSString *finalPath = [testBundle pathForResource:name ofType:ext];
#endif
	
	return finalPath;
}

- (NSString *)_resultStringForFile:(NSString *)file
{
	NSString *filePath = [self pathForTestResource:file ofType:@"html"];
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

- (void)performTest:(XCTestRun *)aRun
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
	XCTAssertTrue(result, @"Parser should return YES");

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidStartDocument:), nil);
}

- (void)testEndDocument
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidEndDocument:), nil);
}

- (void)testEmptyString
{
	NSString *string = @"";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertFalse(result, @"Parser should return NO for empty string");
}

- (void)testSimpleLine
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];

	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown");
	
	NSString *expected = @"<p>Hello Markdown</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleLineEndingInNewline
{
	NSString *string = @"Hello Markdown\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown");
	
	NSString *expected = @"<p>Hello Markdown</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMultipleLines
{
	NSString *string = @"Hello Markdown\nA second line\nA third line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A second line\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A third line");
	
	NSString *expected = @"<p>Hello Markdown\nA second line\nA third line</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testParagraphBeginEnd
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"p");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"p");
}

#pragma mark - Block Quotes

- (void)testBlockquoteSingleLine
{
	NSString *string = @"> A Quote\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<blockquote><p>A Quote</p>\n</blockquote>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testBlockquoteMultiLine
{
	NSString *string = @"> A Quote\n> With multiple lines\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	// there should be a one blockquote tag
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"blockquote");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"blockquote");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A Quote");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"With multiple lines");
	
	// there should be only a single tag even though there are two \n
	NSArray *tagStarts = [_recorder invocationsMatchingSelector:@selector(parser:didStartElement:attributes:)];
	XCTAssertEqual([tagStarts count], 2, @"There should two tag starts, p and blockquote");
	
	NSArray *tagEnds = [_recorder invocationsMatchingSelector:@selector(parser:didEndElement:)];
	XCTAssertEqual([tagEnds count], 2, @"There should be two tag ends, p and blockquote");
	
	NSString *expected = @"<blockquote><p>A Quote\nWith multiple lines</p>\n</blockquote>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testBlockquoteBold
{
	NSString *string = @"> **Blockquote in Bold**";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<blockquote><p><strong>Blockquote in Bold</strong></p>\n</blockquote>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testBlockQuoteNotTerminatedByEmptyLine
{
	NSString *string = @"> INSIDE\n\nOUTSIDE";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<blockquote><p>INSIDE</p>\n</blockquote><p>OUTSIDE</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

/*
- (void)testBlockquoteStacked
{
	NSString *string = @"> This is the first level of quoting.\n>\n> > This is nested blockquote.\n>\n> Back to the first level.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><del>deleted</del></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}
 */

#pragma mark - Emphasis

- (void)testEmphasisAsterisk
{
	NSString *string = @"Normal *Italic Words* *Incomplete\nand * on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"em");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"em");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"em"]];
	XCTAssertTrue([emStarts count] == 1, @"There should be one tag start");

	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"em"]];
	XCTAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of markers prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Incomplete\n");
	
	NSString *expected = @"<p>Normal <em>Italic Words</em> *Incomplete\nand * on next line</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testEmphasisUnderline
{
	NSString *string = @"Normal _Italic Words_ _Incomplete\nand _ on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"em");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"em");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"em"]];
	XCTAssertTrue([emStarts count] == 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"em"]];
	XCTAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Incomplete\n");
	
	NSString *expected = @"<p>Normal <em>Italic Words</em> _Incomplete\nand _ on next line</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testUtagUnderlineSpecialParserOption
{
	NSString *string = @"Normal _Italic Words_ _Incomplete\nand _ on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionUnderscoreIsUnderline];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"u");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"u");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"u"]];
	XCTAssertTrue([emStarts count] == 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"u"]];
	XCTAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Incomplete\n");
	
	NSString *expected = @"<p>Normal <u>Italic Words</u> _Incomplete\nand _ on next line</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStrongAsterisk
{
	NSString *string = @"Normal **Strong Words** **Incomplete\nand ** on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"strong");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"strong");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"strong"]];
	XCTAssertTrue([emStarts count] == 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"strong"]];
	XCTAssertTrue([emEnds count] == 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Strong Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Incomplete\n");
	
	NSString *expected = @"<p>Normal <strong>Strong Words</strong> **Incomplete\nand ** on next line</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStrongUnderline
{
	NSString *string = @"Normal __Strong Words__ __Incomplete\nand __ on next line";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"strong");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"strong");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"strong"]];
	XCTAssertEqual([emStarts count], 1, @"There should be one tag start");
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"strong"]];
	XCTAssertEqual([emEnds count], 1, @"There should be one tag end");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Strong Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Incomplete\n");
	
	NSString *expected = @"<p>Normal <strong>Strong Words</strong> __Incomplete\nand __ on next line</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testCombinedBoldAndItalics
{
	NSString *string = @"**_Strong Italic Words_**";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><strong><em>Strong Italic Words</em></strong></p>\n";
	NSString *actual = [self _HTMLFromInvocations];

	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMismatchedCombinedBoldAndItalics
{
	NSString *string = @"**_Strong Italic Words**_";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><strong>_Strong Italic Words</strong>_</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStrikethrough
{
	NSString *string = @"~~deleted~~";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p><del>deleted</del></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMismatchedStrikethrough
{
	NSString *string = @"~~deleted~";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p>~~deleted~</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testAsterisksWithSpaces
{
	NSString *string = @"Where are * asterisks *";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	
	NSString *expected = @"<p>Where are * asterisks *</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Heading

- (void)testHeadingWithHash
{
	NSString *string = @"Normal\n\n# Heading 1\n\n## Heading 2\n\n";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	// there should be only one h1 starting
	NSArray *h1Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	XCTAssertTrue([h1Starts count] == 1, @"There should be one H1 start");
	
	// there should be only one h1 closing
	NSArray *h1Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h1"]];
	XCTAssertTrue([h1Ends count] == 1, @"There should be one H1 end");

	// there should be only one h2 starting
	NSArray *h2Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	XCTAssertTrue([h2Starts count] == 1, @"There should be one H2 start");
	
	// there should be only one h2 closing
	NSArray *h2Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h2"]];
	XCTAssertTrue([h2Ends count] == 1, @"There should be one H2 end");

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
	XCTAssertTrue(result, @"Parser should return YES");
	
	// there should be only one h1 starting
	NSArray *h1Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	XCTAssertTrue([h1Starts count] == 1, @"There should be one H1 start");
	
	// there should be only one h1 closing
	NSArray *h1Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h1"]];
	XCTAssertTrue([h1Ends count] == 1, @"There should be one H1 end");
	
	// look for correct trims
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Heading 1");
}

- (void)testHeadingWithFollowingEquals
{
	NSString *string = @"Heading 1\n=========\n\nNormal";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h1>Heading 1</h1>\n<p>Normal</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
	
	// there should be only one h1 starting
	NSArray *h1Starts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"h1"]];
	XCTAssertTrue([h1Starts count] == 1, @"There should be one H1 start");
	
	// there should be only one h1 closing
	NSArray *h1Ends = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"h1"]];
	XCTAssertTrue([h1Ends count] == 1, @"There should be one H1 end");
	
	// look for correct trims
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Heading 1");
}

- (void)testHeading1WithFollowingParagraph
{
	NSString *string = @"Heading 1\n=========\nParagraph";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h1>Heading 1</h1>\n<p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeading2WithFollowingParagraph
{
	NSString *string = @"Heading 2\n---------\nParagraph";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h2>Heading 2</h2>\n<p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeading1WithFollowingParagraphAndGitHubLineBreaks
{
	NSString *string = @"Heading 1\n=========\nParagraph";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h1>Heading 1</h1>\n<p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeading2WithFollowingParagraphAndGitHubLineBreaks
{
	NSString *string = @"Heading 2\n---------\nParagraph";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h2>Heading 2</h2>\n<p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeading1WithHashesFollowedBySpace
{
	NSString *string = @"# Heading 1 # ";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h1>Heading 1 #</h1>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeadingFollowedByHeading
{
	NSString *string = @"## Heading 1 #####\n## Heading 2 ##\nFoo";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<h2>Heading 1</h2>\n<h2>Heading 2</h2>\n<p>Foo</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeadingFollowingListNonIndented
{
	NSString *string = @"6. List\n\nHeader\n------\n\nParagraph";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>List</li></ol><h2>Header</h2>\n<p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHeadingFollowingListIndented
{
	NSString *string = @"6. List\n\n Header\n------\n\nParagraph";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>List<h2>Header</h2>\n</li></ol><p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Line Break

- (void)testGitHubLineBreaks
{
	NSString *string = @"Line1\nLine2\n\nLine3";
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1<br />Line2</p>\n<p>Line3</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testGruberLineBreaks
{
	NSString *string = @"Line1  \nLine2\n\nLine3";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1<br />Line2</p>\n<p>Line3</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Hanging Paragraphs

- (void)testHangingOnList
{
	NSString *string = @"- one  \ntwo";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ul><li>one<br />two</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHangingOnListOneBROneNL
{
	NSString *string = @"- one  \ntwo\nthree";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ul><li>one<br />two\nthree</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHangingOfParagraphOnOneLevelList
{
	NSString *string = @"- one\n\n two";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ul><li><p>one</p>\n<p>two</p>\n</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHangingOfParagraphReturningToNonHanging
{
	NSString *string = @"- one\n\n two\n\nnormal";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ul><li><p>one</p>\n<p>two</p>\n</li></ul><p>normal</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}


#pragma mark - Horizontal Rule

- (void)testHorizontalRule
{
	NSString *string = @"Line1\n\n * * *\n\n - - -\n\nLine2";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1</p>\n<hr />\n<hr />\n<p>Line2</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHorizontalRuleAfterParagraphWithOnlyOneNL
{
	NSString *string = @"Line1\n___\nLine2";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Line1</p>\n<hr />\n<p>Line2</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHorizontalRuleWithTooManySpaces
{
	NSString *string = @"-   -   -";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>-   -   -</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHorizontalRuleFollowingListNonIndented
{
	NSString *string = @"6. List\n\n***";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>List</li></ol><hr />\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testHorizontalRuleFollowingListIndented
{
	NSString *string = @"6. List\n\n ***";
	
	DTMarkdownParser *parser = [self _parserForString:string options:DTMarkdownParserOptionGitHubLineBreaks];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>List<hr />\n</li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Links

- (void)testInlineLink
{
	NSString *string = @"Here is [a hyperlink](http://www.cocoanetics.com)";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is <a href=\"http://www.cocoanetics.com\">a hyperlink</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoClosingSquareBracket
{
	NSString *string = @"Here is [not a hyperlink";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is [not a hyperlink</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoClosingRoundBracket
{
	NSString *string = @"Not a [hyperlink](http://foo";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Not a [hyperlink](http://foo</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoRoundBrackets
{
	NSString *string = @"Here is [not a hyperlink] and more text";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is [not a hyperlink] and more text</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}
- (void)testInlineLinkSpacesBetweenSquareAndRoundBracket
{
	NSString *string = @"Here is [a hyperlink]     (http://www.cocoanetics.com)";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is <a href=\"http://www.cocoanetics.com\">a hyperlink</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineLinkNoRoundBracketsButOtherMarkings
{
	NSString *string = @"Here is [__*not a hyperlink*__] word";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is [<strong><em>not a hyperlink</em></strong>] word</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testMultipleSimpleLinksOnMultipleLines
{
	NSString *string = @"Here is [GitHub](http://www.github.com) and [Cocoanetics](http://www.cocoanetics.com).\n\nAnd on new line even [Wikipedia](http://www.wikipedia.org).";

	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Here is <a href=\"http://www.github.com\">GitHub</a> and <a href=\"http://www.cocoanetics.com\">Cocoanetics</a>.</p>\n<p>And on new line even <a href=\"http://www.wikipedia.org\">Wikipedia</a>.</p>\n";
	
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLink
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkTitleInSingleQuotes
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com 'title'\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\" title=\"title\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkTitleInDoubleQuotes
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com \"title\"\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\" title=\"title\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkTitleInRoundBrackets
{
	NSString *string = @"This is a [link with reference][used].\n\n[used]: http://foo.com (title)\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\" title=\"title\">link with reference</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkNonClosed
{
	NSString *string = @"This is a [link with reference][used.\n\n[used]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a [link with reference][used.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkUsingTitleAsRef
{
	NSString *string = @"This is a [Link][].\n\n[link]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a <a href=\"http://foo.com\">Link</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkUsingTitleAsRefWithoutMatch
{
	NSString *string = @"This is not a [Link][].\n\n[otherlink]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is not a [Link][].</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testDoubleSquareLinkMissingClose
{
	NSString *string = @"This is not a [Link][.\n\n[link]: http://foo.com\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is not a [Link][.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testLinkWithAngleBrackets
{
	NSString *string = @"This is a link to <http://foo.com>\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a link to <a href=\"http://foo.com\">http://foo.com</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testLinkWithReferenceOnAnotherLine
{
	NSString *string = @"This is a link to [something][id]\n\n[id]: http://foo.bar\n  \"Optional Title Here\"";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a link to <a href=\"http://foo.bar\" title=\"Optional Title Here\">something</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testLinkWithNestedImagesInside
{
	NSString *string = @"[![Build Status](https://travis-ci.org/Cocoanetics/DTMarkdownParser.png?branch=develop)](https://travis-ci.org/Cocoanetics/DTMarkdownParser)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><a href=\"https://travis-ci.org/Cocoanetics/DTMarkdownParser\"><img alt=\"Build Status\" src=\"https://travis-ci.org/Cocoanetics/DTMarkdownParser.png?branch=develop\" /></a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testLinkWithNestedImagesInsideAndExtraMarkdownText
{
	NSString *string = @"[before *image* ![Build Status](https://travis-ci.org/Cocoanetics/DTMarkdownParser.png?branch=develop) after *image*](https://travis-ci.org/Cocoanetics/DTMarkdownParser)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><a href=\"https://travis-ci.org/Cocoanetics/DTMarkdownParser\">before <em>image</em> <img alt=\"Build Status\" src=\"https://travis-ci.org/Cocoanetics/DTMarkdownParser.png?branch=develop\" /> after <em>image</em></a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testAutoLinking
{
	NSString *string = @"Look at http://www.cococanetics.com for more info";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Look at <a href=\"http://www.cococanetics.com\">http://www.cococanetics.com</a> for more info</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testAutoLinkingNumber
{
	NSString *string = @"This is a sample of a http://abc.com/efg.php?EFAei687e3EsA sentence with a URL within it and a number 097843.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This is a sample of a <a href=\"http://abc.com/efg.php?EFAei687e3EsA\">http://abc.com/efg.php?EFAei687e3EsA</a> sentence with a URL within it and a number 097843.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testAutoLinkingEmail
{
	NSString *string = @"Mail me at oliver@cocoanetics.com.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Mail me at <a href=\"mailto:oliver@cocoanetics.com\">oliver@cocoanetics.com</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testAutoLinkingEmailInsideCode
{
	NSString *string = @"`Mail me at oliver@cocoanetics.com.`";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><code>Mail me at oliver@cocoanetics.com.</code></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testAutoLinkingEmailInsidePre
{
	NSString *string = @"```\nMail me at oliver@cocoanetics.com.\n```";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<pre><code>Mail me at oliver@cocoanetics.com.\n</code></pre>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testForcedLinkEmail
{
	NSString *string = @"Mail me at <oliver@cocoanetics.com>.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Mail me at <a href=\"mailto:oliver@cocoanetics.com\">oliver@cocoanetics.com</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testForcedInvalidLink
{
	NSString *string = @"Mail me at <abc>.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Mail me at <a href=\"abc\">abc</a>.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testForcedInvalidLink2
{
	NSString *string = @"Mail me at <abc def>.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Mail me at &lt;abc def&gt;.</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 6
- (void)testLinkWithNewlineInText
{
	NSString *string = @"This: [Patch\nDemo](http://foo.bar/demo.html)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>This: <a href=\"http://foo.bar/demo.html\">Patch\nDemo</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 6
- (void)testLinkWithNewlineInTextInListItem
{
	NSString *string = @"- [Patch\nDemo](http://foo.bar/demo.html)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ul><li><a href=\"http://foo.bar/demo.html\">Patch\nDemo</a></li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testLinkWithSingleSpecialChar
{
	NSString *string = @"[Patch * Demo](http://foo.bar/demo.html)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><a href=\"http://foo.bar/demo.html\">Patch * Demo</a></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 14: link inside emphasis
- (void)testLinkInEmphasis
{
	NSString *string = @"_You can follow me on [Twitter](http://twitter.com/me)._";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><em>You can follow me on <a href=\"http://twitter.com/me\">Twitter</a>.</em></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}


#pragma mark - Images

- (void)testInlineImage
{
	NSString *string = @"![Alt text](/path/to/img.jpg)";

	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><img alt=\"Alt text\" src=\"/path/to/img.jpg\" /></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineImageWithSize
{
	NSString *string = @"![Alt text](/path/to/img.jpg=1000x2000)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><img alt=\"Alt text\" height=\"2000\" src=\"/path/to/img.jpg\" width=\"1000\" /></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}


- (void)testInlineImageMissingCloseingSquareBracket
{
	NSString *string = @"![Alt text (/path/to/img.jpg)";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>![Alt text (/path/to/img.jpg)</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testRefStyleImage
{
	NSString *string = @"![Alt text][id]\n\n[id]: /path/to/img.jpg  \"Optional title attribute\"";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><img alt=\"Alt text\" src=\"/path/to/img.jpg\" title=\"Optional title attribute\" /></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testImageInlineTitle
{
	NSString *string = @"![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png \"Logo Title Text 1\")";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p><img alt=\"alt text\" src=\"https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png\" title=\"Logo Title Text 1\" /></p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Preformatted Text

- (void)testIndentedCodeBlock
{
	NSString *string = @"Normal text\n\n    10 print \"Hello World\"\n    20 goto 10";

	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal text</p>\n<pre><code>10 print &quot;Hello World&quot;\n20 goto 10</code></pre>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testIndentedCodeBlockWithTab
{
	NSString *string = @"Normal text\n\n\t10 print \"Hello World\"\n\t20 goto 10";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal text</p>\n<pre><code>10 print &quot;Hello World&quot;\n20 goto 10</code></pre>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testIndentedCodeBlockMissingEmptyLineBefore
{
	NSString *string = @"Normal text\n    10 print \"Hello World\"\n    20 goto 10";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal text\n10 print &quot;Hello World&quot;\n20 goto 10</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineCodeBlock
{
	NSString *string = @"Consider the `NSString` class";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Consider the <code>NSString</code> class</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testInlineCodeBlockWithFurtherMarkers
{
	NSString *string = @"Consider the `*NSString*` class";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Consider the <code>*NSString*</code> class</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testFencedCodeBlock
{
	NSString *string = @"Normal\n```\n10 print \"Hello World\"\n20 goto 10\n```\nNormal";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<pre><code>10 print &quot;Hello World&quot;\n20 goto 10\n</code></pre>\n<p>Normal</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 10
- (void)testMultipleQuotes
{
	NSString *string = @"    \"\"\" multiple quotes \"\"\"";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<pre><code>&quot;&quot;&quot; multiple quotes &quot;&quot;&quot;</code></pre>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 11
- (void)testPreformattedWithNewline
{
	NSString *string = @"```\nLine1\n\nLine2\n```";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<pre><code>Line1\n\nLine2\n</code></pre>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 11
- (void)testPreformattedWithNewlineSpaces
{
	NSString *string = @"Normal\n\n    Line 1\n\n    Line 2\n\nNormal";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<pre><code>Line 1\n\nLine 2\n</code></pre>\n<p>Normal</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

// issue 10
- (void)testMultipleBackticks
{
	NSString *string = @"    ``` multiple quotes ```";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<pre><code>``` multiple quotes ```</code></pre>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Lists (1 Level)

- (void)testSimpleList
{
	NSString *string = @"Normal\n   * one\n   * two\n   * three";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ul><li>one</li><li>two</li><li>three</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleListWithMixedPrefixes
{
	NSString *string = @"Normal\n   * one\n   1. two\n   2. three";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ul><li>one</li><li>two</li><li>three</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleListWithEmptyLinesBefore
{
	NSString *string = @"Normal\n\n\n   * one\n   * two\n   * three";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ul><li>one</li><li>two</li><li>three</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleListWithEmptyLinesAfter
{
	NSString *string = @"Normal\n   * one\n   * two\n   * three\n\n\n";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ul><li>one</li><li>two</li><li>three</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleListWithIgnoredLineAfter
{
	NSString *string = @"Normal\n   * one\n   * two\n   * three\n[id]: http://foo.com";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ul><li>one</li><li>two</li><li>three</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleOrderedList
{
	NSString *string = @"Normal\n   1. one\n   2. two\n   3. three";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ol><li>one</li><li>two</li><li>three</li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleOrderedListWithMixedPrefixes
{
	NSString *string = @"Normal\n   1. one\n   * two\n   * three";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Normal</p>\n<ol><li>one</li><li>two</li><li>three</li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testSimpleOrderedListBetweenParagraphs
{
	NSString *string = @"Paragraph\n\n- One\n- Two\n- Three\n- Four\n\nParagraph";

	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<p>Paragraph</p>\n<ul><li>One</li><li>Two</li><li>Three</li><li>Four</li></ul><p>Paragraph</p>\n";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Lists (Stacked)

- (void)testStackedLists
{
	NSString *string = @"1. Lists in a list item:\n    - Indented four spaces.\n        * indented eight spaces.\n    - Four spaces again.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>Lists in a list item:<ul><li>Indented four spaces.<ul><li>indented eight spaces.</li></ul></li><li>Four spaces again.</li></ul></li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStackedListsWithTab
{
	NSString *string = @"1. Lists in a list item:\n\t- Indented with tab.\n\t\t* two tabs.\n\t- One tab again.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>Lists in a list item:<ul><li>Indented with tab.<ul><li>two tabs.</li></ul></li><li>One tab again.</li></ul></li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStackedListsClosingTwoLevels
{
	NSString *string = @"1. Lists in a list item:\n    - Indented four spaces.\n        * indented eight spaces.\n- Top level again.";
	
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = @"<ol><li>Lists in a list item:<ul><li>Indented four spaces.<ul><li>indented eight spaces.</li></ul></li></ul></li><li>Top level again.</li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStackedListsManySpaces
{
	NSString *string = @"- one\n       - two\n                                     MUCH";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	// no P around two/MUCH
	NSString *expected = @"<ul><li>one<ul><li>two\nMUCH</li></ul></li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testStackedListsDashBug
{
	NSString *string = @"- zero\n    - one\n       - two";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	// no P around two/MUCH
	NSString *expected = @"<ul><li>zero<ul><li>one<ul><li>two</li></ul></li></ul></li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testListFollowing
{
	NSString *string = @"   1. one\n     - two\n\n- bla";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	// no P around two/MUCH
	NSString *expected = @"<ol><li>one<ul><li>two</li></ul></li></ol><ul><li>bla</li></ul>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testListWithSubItemHavingLessSpacesThanHead
{
	NSString *string = @"   1. one\n       - two\n - three";
	DTMarkdownParser *parser = [self _parserForString:string options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	// no P around two/MUCH
	NSString *expected = @"<ol><li>one<ul><li>two<ul><li>three</li></ul></li></ul></li></ol>";
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

#pragma mark - Test Files

- (void)testFileEmphasis
{
	DTMarkdownParser *parser = [self _parserForFile:@"emphasis" options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"emphasis"];
	
	NSLog(@"expected: %@", expected);
	
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testFileHeader
{
	DTMarkdownParser *parser = [self _parserForFile:@"header" options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"header"];
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

- (void)testFileHR
{
	DTMarkdownParser *parser = [self _parserForFile:@"hr" options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"hr"];
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}

/*
 // doesn't work yet due to HTML entities differing

- (void)testFileHRSpaces
{
	DTMarkdownParser *parser = [self _parserForFile:@"hr_spaces" options:0];
	
	BOOL result = [parser parse];
	STAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"hr_spaces"];
	NSString *actual = [self _HTMLFromInvocations];
	
	STAssertEqualObjects(actual, expected, @"Expected result did not match");
}
*/

- (void)testFileMissingLinkDefn
{
	DTMarkdownParser *parser = [self _parserForFile:@"missing_link_defn" options:0];
	
	BOOL result = [parser parse];
	XCTAssertTrue(result, @"Parser should return YES");
	
	NSString *expected = [self _resultStringForFile:@"missing_link_defn"];
	NSString *actual = [self _HTMLFromInvocations];
	
	XCTAssertEqualObjects(actual, expected, @"Expected result did not match");
}



@end
