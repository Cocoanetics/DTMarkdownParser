//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"

#import <SenTestingKit/SenTestingKit.h>
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

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

- (void)testCreateParser
{
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:@"Hello Markdown"];
	
	STAssertNotNil(parser, @"Should be able to create parser");
	
	BOOL result = [parser parse];

	STAssertTrue(result, @"Parsing should work");
}

- (void)testStartDocument
{
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:@"Hello Markdown"];
	
	STAssertNotNil(parser, @"Should be able to create parser");

	id <DTMarkdownParserDelegate> delegate = mockProtocol(@protocol(DTMarkdownParserDelegate));
	parser.delegate = delegate;
	
	BOOL result = [parser parse];
	
	[verify(delegate) parserDidStartDocument:(id)parser];
	
	STAssertTrue(result, @"Parsing should work");
}

@end
