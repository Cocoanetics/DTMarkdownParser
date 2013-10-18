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


@interface DTMarkdownParserTest : SenTestCase

@end

@implementation DTMarkdownParserTest
{
	DTInvocationRecorder *_recorder;
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

@end
