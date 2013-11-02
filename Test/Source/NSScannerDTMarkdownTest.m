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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testRefWithMultipleLines
{
	NSString *string = @"[id]: http://foo.bar\n  \"Optional Title Here\"";

	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertTrue(b, @"Should be able to scan ref");
	
	STAssertEqualObjects(href, @"http://foo.bar", @"Wrong href");
	STAssertEqualObjects(title, @"Optional Title Here", @"Wrong title");
	STAssertEqualObjects(ref, @"id", @"Wrong id");
}

- (void)testRefWithMultipleLinesMissingIndent
{
	NSString *string = @"[id]: http://foo.bar\n\"Optional Title Here\"";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	NSString *ref;
	
	BOOL b = [scanner scanMarkdownHyperlinkReferenceLine:&ref URLString:&href title:&title];
	
	STAssertTrue(b, @"Should be able to scan ref");
	
	STAssertEqualObjects(href, @"http://foo.bar", @"Wrong href");
	STAssertNil(title, @"Optional Title Here", @"Wrong title");
	STAssertEqualObjects(ref, @"id", @"Wrong id");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanListPrefixOnlySpaces
{
	NSString *string = @"  ";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	STAssertFalse(b, @"Should not be able to scan list prefix");
	STAssertNil(prefix, @"prefix should be nil");
	
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

#pragma mark - Marked Range Markers

- (void)_testScanMarkedRangeBeginningsInString:(NSString *)string expectedMarker:(NSString *)expectedMarker
{
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *marker;
	BOOL b = [scanner scanMarkdownBeginMarker:&marker];
	
	STAssertTrue(b, @"Should be able to scan opening marker");
	STAssertEqualObjects(expectedMarker, marker, @"Incorrect Marker scanned");
}

- (void)testScanMarkedRanges
{
	[self _testScanMarkedRangeBeginningsInString:@"**Bold**" expectedMarker:@"**"];
	[self _testScanMarkedRangeBeginningsInString:@"*Emphasis*" expectedMarker:@"*"];
	[self _testScanMarkedRangeBeginningsInString:@"__Bold__" expectedMarker:@"__"];
	[self _testScanMarkedRangeBeginningsInString:@"_Emphasis_" expectedMarker:@"_"];
	[self _testScanMarkedRangeBeginningsInString:@"~~Deleted~~" expectedMarker:@"~~"];
	[self _testScanMarkedRangeBeginningsInString:@"`Code`" expectedMarker:@"`"];
}

- (void)testMarkdownTextBetweenMarkersWithNewline
{
	NSScanner *scanner = [NSScanner scannerWithString:@"*space\nnewline*"];
	scanner.charactersToBeSkipped = nil;
	
	NSString *marker;
	NSString *text;
	BOOL b = [scanner scanMarkdownTextBetweenFormatMarkers:&text outermostMarker:&marker];
	
	STAssertFalse(b, @"Should not be able to scan formatted text with newline in it");
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

#pragma mark - Link Scanning

- (void)testScanImage
{
	NSString *string = @"![Alt text](/path/to/img.jpg \"Optional title\")";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	STAssertTrue(b, @"Should be able to scan opening marker");
	STAssertEqualObjects(attributes[@"src"], @"/path/to/img.jpg", @"Incorrect SRC");
	STAssertEqualObjects(attributes[@"alt"], @"Alt text", @"Incorrect ALT");
	STAssertEqualObjects(attributes[@"title"], @"Optional title", @"Incorrect TITLE");
}

- (void)testScanImageNoLink
{
	NSString *string = @"![Alt text]()";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	STAssertFalse(b, @"Should not be able to scan image");
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanImageNoClosingBracketAfterLink
{
	NSString *string = @"![Alt text](http://foo.com";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	STAssertFalse(b, @"Should not be able to scan image");
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanImageEmptyReference
{
	NSString *string = @"![Alt][]";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	STAssertFalse(b, @"Should not be able to scan image");
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanImageExistingReferenceButMissingClosingBracket
{
	NSString *string = @"![Alt][";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:@{@"alt":@{@"href": @"http://foo.com"}}];
	
	STAssertFalse(b, @"Should not be able to scan image");
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanLinkExistingReferenceButMissingClosingBracket
{
	NSString *string = @"[Alt][";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	NSString *enclosed;
	BOOL b = [scanner scanMarkdownHyperlinkAttributes:&attributes enclosedString:&enclosed references:@{@"alt":@{@"href": @"http://foo.com"}}];
	
	STAssertFalse(b, @"Should not be able to scan image");
	STAssertEquals(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}
- (void)testEmptyLink
{
	NSString *string = @"[Link]()";

	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	NSString *enclosed;
	BOOL b = [scanner scanMarkdownHyperlinkAttributes:&attributes enclosedString:&enclosed references:nil];
	
	STAssertTrue(b, @"Should result in scanned link");
	
	STAssertEqualObjects(@"Link", enclosed, @"Wrong enclosed string");
	STAssertEquals([attributes count], (NSUInteger)0, @"There should be no attributes");
}

@end
