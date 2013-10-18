//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
#import "DTMarkdownParserDelegateLogger.h"


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
	DTMarkdownParserDelegateLogger *logger = [[DTMarkdownParserDelegateLogger alloc] init];
	DTMarkdownParser *parser = [self _parserForString:@"Hello Markdown" delegate:logger];
	
	BOOL result = [parser parse];

	assertThatBool(result, is(equalToBool(YES)));
	
	assertThatInteger([logger.log count], is(equalToInt(3)));
	
	NSInvocation *firstCall = logger.log[0];
	STAssertTrue(firstCall.selector == @selector(parserDidStartDocument:), nil);
}

//- (void)testEndDocument
//{
//	id <DTMarkdownParserDelegate> delegate = mockProtocol(@protocol(DTMarkdownParserDelegate));
//	DTMarkdownParser *parser = [self _parserForString:@"Hello Markdown" delegate:delegate];
//	
//	BOOL result = [parser parse];
//	assertThatBool(result, is(equalToBool(YES)));
//	
//	[verifyCount(delegate, times(1)) parserDidEndDocument:(id)parser];
//}

//- (void)testSimpleLine
//{
//	id <DTMarkdownParserDelegate> delegate = mockProtocol(@protocol(DTMarkdownParserDelegate));
//	DTMarkdownParser *parser = [self _parserForString:@"Hello Markdown" delegate:delegate];
//	
//	BOOL result = [parser parse];
//	assertThatBool(result, is(equalToBool(YES)));
//	
//	[verifyCount(delegate, times(1)) parser:(id)parser foundCharacters:@"Hello Markdown"];
//}

//- (void)testTwoLines
//{
//	id <DTMarkdownParserDelegate> logger = [[DTMarkdownParserDelegateLogger alloc] init];
//	DTMarkdownParser *parser = [self _parserForString:@"Hello Markdown\nLine 2" delegate:logger];
//	
//	BOOL result = [parser parse];
//	assertThatBool(result, is(equalToBool(YES)));
//}
@end
