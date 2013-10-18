//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
#import "DTMarkdownParserDelegateLogger.h"
#import "DTInvocationRecorder.h"
#import "NSInvocation+DTFoundation.h"


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

- (BOOL)_invocationsRecorder:(DTInvocationRecorder *)recorder containsCallToSelector:(SEL)selector andParameter:(id)parameter
{
	NSArray *invocations = [recorder invocationsMatchingSelector:selector];
	
	if (![invocations count])
	{
		return NO;
	}
	
	NSInvocation *firstInvocation = invocations[0];
	
	if (firstInvocation.selector != selector)
	{
		return NO;
	}
	
	NSUInteger numberOfArguments = [firstInvocation.methodSignature numberOfArguments];
	
	for (NSUInteger i=2; i<numberOfArguments; i++)
	{
		const char *type = [firstInvocation.methodSignature getArgumentTypeAtIndex:i];
		
		if (type[0] == '@')
		{
			id arg;
			[firstInvocation getArgument:&arg atIndex:i];
			
			if ([arg isEqual:parameter])
			{
				return YES;
			}
		}
	}
	
	return NO;
}


- (void)testStartDocument
{
	//DTMarkdownParserDelegateLogger *logger = [[DTMarkdownParserDelegateLogger alloc] init];
	
	DTInvocationRecorder *recorder = [[DTInvocationRecorder alloc] init];
	[recorder addProtocol:@protocol(DTMarkdownParserDelegate)];
	
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string delegate:(id)recorder];
	
	BOOL result = [parser parse];

	assertThatBool(result, is(equalToBool(YES)));
	
	assertThatBool([self _invocationsRecorder:recorder containsCallToSelector:@selector(parser:foundCharacters:) andParameter:string], is(equalToBool(YES)));

//	NSInvocation *line = [lines lastObject];
//	NSString *argument = [line getArgumentAtIndexAsObject:3];
//	
//	assertThat(argument, is(equalTo(string)));
//	
//	assertThatBool(result, is(equalToBool(YES)));
//	
//	assertThatInteger([recorder.invocations count], is(equalToInt(3)));
//
//	NSInvocation *firstCall = logger.log[0];
//	STAssertTrue(firstCall.selector == @selector(parserDidStartDocument:), nil);
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
