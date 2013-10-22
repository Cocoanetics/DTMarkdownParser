//
//  NSScannerDTMarkdownTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 21.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSScanner+DTMarkdown.h"

@interface NSScannerDTMarkdownTest : SenTestCase

@end

@implementation NSScannerDTMarkdownTest

#pragma mark - Link Scanning

- (void)testScanLinkFromWhitespace
{
	NSString *string = @"     ";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	BOOL b = [scanner scanMarkdownHyperlink:NULL title:NULL];
	
	STAssertFalse(b, @"Should not be able to scan hyperlink");
}

- (void)testMissingClosingSingleQuote
{
	NSString *string = @"http://foo.com 'Title";

	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;

	NSString *href;
	NSString *title;
	
	BOOL b = [scanner scanMarkdownHyperlink:&href title:&title];

	STAssertTrue(b, @"Should be able to scan hyperlink");

	STAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	
	STAssertNil(title, @"Title should be nil");
	
	STAssertEquals([scanner scanLocation], (NSUInteger)14, @"Scan position should be after href");
}

- (void)testMissingClosingDoubleQuote
{
	NSString *string = @"http://foo.com     \"Title";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	
	BOOL b = [scanner scanMarkdownHyperlink:&href title:&title];
	
	STAssertTrue(b, @"Should be able to scan hyperlink");
	
	STAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	
	STAssertNil(title, @"Title should be nil");
	
	STAssertEquals([scanner scanLocation], (NSUInteger)14, @"Scan position should be after href");
}

- (void)testMissingClosingRoundBracket
{
	NSString *string = @"http://foo.com     (Title";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	
	BOOL b = [scanner scanMarkdownHyperlink:&href title:&title];
	
	STAssertTrue(b, @"Should be able to scan hyperlink");
	
	STAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	
	STAssertNil(title, @"Title should be nil");
	
	STAssertEquals([scanner scanLocation], (NSUInteger)14, @"Scan position should be after href");
}

#pragma mark - Ref Line Scanning

- (void)testNormalRefLine
{
	NSString *string = @"[foo]: http://foo.com     (Title)";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertTrue(b, @"Should be able to scan hyperlink");
	
	STAssertEqualObjects(ref, @"foo", @"incorrect ref");
	STAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	STAssertEqualObjects(title, @"Title", @"incorrect title");
}

- (void)testMissingRefEmptyID
{
	NSString *string = @"[]: http://foo.com     (Title)";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertFalse(b, @"Should not be able to scan hyperlink");
	
	STAssertNil(href, @"href should be nil");
	STAssertNil(title, @"Title should be nil");
	STAssertNil(ref, @"href should be nil");
}

- (void)testMissingRefClosingBracket
{
	NSString *string = @"[foo] http://foo.com     (Title)";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertFalse(b, @"Should not be able to scan hyperlink");
	
	STAssertNil(href, @"href should be nil");
	STAssertNil(title, @"Title should be nil");
	STAssertNil(ref, @"href should be nil");
}

- (void)testMissingSpacesAfterID
{
	NSString *string = @"[foo]:http://foo.com     (Title)";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertFalse(b, @"Should not be able to scan hyperlink");
	
	STAssertNil(href, @"href should be nil");
	STAssertNil(title, @"Title should be nil");
	STAssertNil(ref, @"href should be nil");
}

- (void)testRefWithInvalidHyperlink
{
	NSString *string = @"[foo]: ";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertFalse(b, @"Should not be able to scan hyperlink");
	
	STAssertNil(href, @"href should be nil");
	STAssertNil(title, @"Title should be nil");
	STAssertNil(ref, @"href should be nil");
}

#pragma mark - List Prefix

- (void)testScanListPrefixTooManySpaces
{
	NSString *string = @"       * one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertFalse(b, @"Should not be able to scan list prefix");
	STAssertNil(prefix, @"prefix should be nil");
}

- (void)testScanListPrefixMissingWhitespace
{
	NSString *string = @"*one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertFalse(b, @"Should not be able to scan list prefix");
	STAssertNil(prefix, @"prefix should be nil");
}

- (void)testScanListPrefixAsterisk
{
	NSString *string = @"  * one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertTrue(b, @"Should be able to scan list prefix");
	STAssertEqualObjects(prefix, @"*", @"prefix incorrect");
}

- (void)testScanListPrefixPlus
{
	NSString *string = @"  + one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertTrue(b, @"Should be able to scan list prefix");
	STAssertEqualObjects(prefix, @"+", @"prefix incorrect");
}

- (void)testScanListPrefixMinus
{
	NSString *string = @"  + one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertTrue(b, @"Should be able to scan list prefix");
	STAssertEqualObjects(prefix, @"+", @"prefix incorrect");
}

- (void)testScanListPrefixInvalid
{
	NSString *string = @"  _ one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertFalse(b, @"Should not be able to scan list prefix");
	STAssertNil(prefix, @"prefix should be nil");
}

- (void)testScanListPrefixNumber
{
	NSString *string = @"  1. one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertTrue(b, @"Should be able to scan list prefix");
	STAssertEqualObjects(prefix, @"1.", @"prefix incorrect");
}

- (void)testScanListPrefixInvalidNumber
{
	NSString *string = @"  a1. one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertFalse(b, @"Should not be able to scan list prefix");
	STAssertNil(prefix, @"prefix should be nil");
}
@end
