//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"

@interface DTMarkdownParserTest : SenTestCase

@end

@implementation DTMarkdownParserTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 
    [super tearDown];
}

- (DTMarkdownParser *)_parserForString:(NSString *)string delegate:(id<DTMarkdownParserDelegate>)delegate
{
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:string];
	STAssertNotNil(parser, @"Should be able to create parser");
	
	assertThat(parser, is(notNilValue()));
	
	parser.delegate = delegate;
	
	return parser;
}

- (void)testStartDocument
{
	id <DTMarkdownParserDelegate> delegate = mockProtocol(@protocol(DTMarkdownParserDelegate));
	DTMarkdownParser *parser = [self _parserForString:@"Hello Markdown" delegate:delegate];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	[verifyCount(delegate, times(1)) parserDidStartDocument:(id)parser];
}

- (void)testEndDocument
{
	id <DTMarkdownParserDelegate> delegate = mockProtocol(@protocol(DTMarkdownParserDelegate));
	DTMarkdownParser *parser = [self _parserForString:@"Hello Markdown" delegate:delegate];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	[verifyCount(delegate, times(1)) parserDidEndDocument:(id)parser];
}

@end
