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
	
	for (NSInvocation *invocation in _recorder.invocations)
	{
		if (invocation.selector == @selector(parser:didEndElement:))
		{
			NSString *tag = [invocation argumentAtIndexAsObject:3];
			
			[tmpString appendFormat:@"</%@>", tag];
			
			if ([tag isEqualToString:@"p"])
			{
				[tmpString appendString:@"\n"];
			}
		}
		else if (invocation.selector == @selector(parser:didStartElement:attributes:))
		{
			NSString *tag = [invocation argumentAtIndexAsObject:3];
			
			[tmpString appendFormat:@"<%@>", tag];
		}
		else 	if (invocation.selector == @selector(parser:foundCharacters:))
		{
			NSString *string = [invocation argumentAtIndexAsObject:3];
			
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

- (DTMarkdownParser *)_parserForString:(NSString *)string
{
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:string];
	STAssertNotNil(parser, @"Should be able to create parser");
	
	assertThat(parser, is(notNilValue()));
	
	if (_recorder)
	{
		parser.delegate = (id<DTMarkdownParserDelegate>)_recorder;
	}
	
	return parser;
}

- (DTMarkdownParser *)_parserForFile:(NSString *)file
{
	NSString * filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"text"];
	NSString *string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
	
	return [self _parserForString:string];
}

- (NSString *)_resultStringForFile:(NSString *)file
{
	NSString * filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
	return [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
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
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidStartDocument:), nil);
}

- (void)testEndDocument
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidEndDocument:), nil);
}

- (void)testSimpleLine
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];

	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown");
}

- (void)testMultipleLines
{
	NSString *string = @"Hello Markdown\nA second line\nA third line";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A second line\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A third line");
}

- (void)testParagraphBeginEnd
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"p");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"p");
}

- (void)testBlockquote
{
	NSString *string = @"> A Quote\n> With multiple lines\n";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	// there should be a one blockquote tag
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"blockquote");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"blockquote");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A Quote\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"With multiple lines");
	// there should be only a single tag even though there are two \n
	NSArray *tagStarts = [_recorder invocationsMatchingSelector:@selector(parser:didStartElement:attributes:)];
	assertThatInteger([tagStarts count], is(equalToInteger(1)));

	NSArray *tagEnds = [_recorder invocationsMatchingSelector:@selector(parser:didEndElement:)];
	assertThatInteger([tagEnds count], is(equalToInteger(1)));
}

- (void)testEmphasisAsterisk
{
	NSString *string = @"Normal *Italic Words* *Incomplete\nand * on next line";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"em");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"em");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"em"]];
	assertThatInteger([emStarts count], is(equalToInteger(1)));

	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"em"]];
	assertThatInteger([emEnds count], is(equalToInteger(1)));
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"*Incomplete\n");
}

- (void)testEmphasisUnderline
{
	NSString *string = @"Normal _Italic Words_ _Incomplete\nand _ on next line";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"em");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"em");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"em"]];
	assertThatInteger([emStarts count], is(equalToInteger(1)));
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"em"]];
	assertThatInteger([emEnds count], is(equalToInteger(1)));
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Italic Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"_Incomplete\n");
}

- (void)testStrongAsterisk
{
	NSString *string = @"Normal **Strong Words** **Incomplete\nand ** on next line";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"strong");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"strong");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"strong"]];
	assertThatInteger([emStarts count], is(equalToInteger(1)));
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"strong"]];
	assertThatInteger([emEnds count], is(equalToInteger(1)));
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Strong Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"**Incomplete\n");
}

- (void)testStrongUnderline
{
	NSString *string = @"Normal __Strong Words__ __Incomplete\nand __ on next line";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"strong");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"strong");
	
	// there should be only one em starting
	NSArray *emStarts = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingOpeningTag:@"strong"]];
	assertThatInteger([emStarts count], is(equalToInteger(1)));
	
	// there should be only one em closing
	NSArray *emEnds = [_recorder.invocations filteredArrayUsingPredicate:[self _predicateForFindingClosingTag:@"strong"]];
	assertThatInteger([emEnds count], is(equalToInteger(1)));
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Strong Words");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"__Incomplete\n");
}

#pragma mark - Test Files

- (void)testEmphasis
{
	DTMarkdownParser *parser = [self _parserForFile:@"emphasis"];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	NSString *expected = [self _resultStringForFile:@"emphasis"];
	NSString *actual = [self _HTMLFromInvocations];
	
	assertThat(actual, is(equalTo(expected)));
}


@end
