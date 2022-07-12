//
//  NSScannerDTMarkdownTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 21.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@import XCTest;
@import DTMarkdownParser;

@interface NSScannerDTMarkdownTest : XCTestCase

@end

@implementation NSScannerDTMarkdownTest

#pragma mark - Link Scanning

- (void)testScanLinkFromWhitespace
{
	NSString *string = @"     ";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	BOOL b = [scanner scanMarkdownHyperlink:NULL title:NULL];
	
	XCTAssertFalse(b, @"Should not be able to scan hyperlink");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testMissingClosingSingleQuote
{
	NSString *string = @"http://foo.com 'Title";

	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;

	NSString *href;
	NSString *title;
	
	BOOL b = [scanner scanMarkdownHyperlink:&href title:&title];

	XCTAssertTrue(b, @"Should be able to scan hyperlink");

	XCTAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	
	XCTAssertNil(title, @"Title should be nil");
	
	XCTAssertEqual([scanner scanLocation], (NSUInteger)14, @"Scan position should be after href");
}

- (void)testMissingClosingDoubleQuote
{
	NSString *string = @"http://foo.com     \"Title";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	
	BOOL b = [scanner scanMarkdownHyperlink:&href title:&title];
	
	XCTAssertTrue(b, @"Should be able to scan hyperlink");
	
	XCTAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	
	XCTAssertNil(title, @"Title should be nil");
	
	XCTAssertEqual([scanner scanLocation], (NSUInteger)14, @"Scan position should be after href");
}

- (void)testMissingClosingRoundBracket
{
	NSString *string = @"http://foo.com     (Title";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *href;
	NSString *title;
	
	BOOL b = [scanner scanMarkdownHyperlink:&href title:&title];
	
	XCTAssertTrue(b, @"Should be able to scan hyperlink");
	
	XCTAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	
	XCTAssertNil(title, @"Title should be nil");
	
	XCTAssertEqual([scanner scanLocation], (NSUInteger)14, @"Scan position should be after href");
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
	
	XCTAssertTrue(b, @"Should be able to scan hyperlink");
	
	XCTAssertEqualObjects(ref, @"foo", @"incorrect ref");
	XCTAssertEqualObjects(href, @"http://foo.com", @"incorrect href");
	XCTAssertEqualObjects(title, @"Title", @"incorrect title");
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
	
	XCTAssertFalse(b, @"Should not be able to scan hyperlink");
	
	XCTAssertNil(href, @"href should be nil");
	XCTAssertNil(title, @"Title should be nil");
	XCTAssertNil(ref, @"href should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	
	XCTAssertFalse(b, @"Should not be able to scan hyperlink");
	
	XCTAssertNil(href, @"href should be nil");
	XCTAssertNil(title, @"Title should be nil");
	XCTAssertNil(ref, @"href should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	
	XCTAssertFalse(b, @"Should not be able to scan hyperlink");
	
	XCTAssertNil(href, @"href should be nil");
	XCTAssertNil(title, @"Title should be nil");
	XCTAssertNil(ref, @"href should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	
	XCTAssertFalse(b, @"Should not be able to scan hyperlink");
	
	XCTAssertNil(href, @"href should be nil");
	XCTAssertNil(title, @"Title should be nil");
	XCTAssertNil(ref, @"href should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
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
	
	XCTAssertTrue(b, @"Should be able to scan ref");
	
	XCTAssertEqualObjects(href, @"http://foo.bar", @"Wrong href");
	XCTAssertEqualObjects(title, @"Optional Title Here", @"Wrong title");
	XCTAssertEqualObjects(ref, @"id", @"Wrong id");
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
	
	XCTAssertTrue(b, @"Should be able to scan ref");
	
	XCTAssertEqualObjects(href, @"http://foo.bar", @"Wrong href");
	XCTAssertNil(title, @"Wrong title");
	XCTAssertEqualObjects(ref, @"id", @"Wrong id");
}

#pragma mark - List Prefix

- (void)testScanListPrefixTooManySpaces
{
	NSString *string = @"       * one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertFalse(b, @"Should not be able to scan list prefix");
	XCTAssertNil(prefix, @"prefix should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanListPrefixMissingWhitespace
{
	NSString *string = @"*one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertFalse(b, @"Should not be able to scan list prefix");
	XCTAssertNil(prefix, @"prefix should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanListPrefixAsterisk
{
	NSString *string = @"  * one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertTrue(b, @"Should be able to scan list prefix");
	XCTAssertEqualObjects(prefix, @"*", @"prefix incorrect");
}

- (void)testScanListPrefixPlus
{
	NSString *string = @"  + one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertTrue(b, @"Should be able to scan list prefix");
	XCTAssertEqualObjects(prefix, @"+", @"prefix incorrect");
}

- (void)testScanListPrefixMinus
{
	NSString *string = @"  + one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertTrue(b, @"Should be able to scan list prefix");
	XCTAssertEqualObjects(prefix, @"+", @"prefix incorrect");
}

- (void)testScanListPrefixInvalid
{
	NSString *string = @"  _ one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertFalse(b, @"Should not be able to scan list prefix");
	XCTAssertNil(prefix, @"prefix should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanListPrefixNumber
{
	NSString *string = @"  1. one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertTrue(b, @"Should be able to scan list prefix");
	XCTAssertEqualObjects(prefix, @"1.", @"prefix incorrect");
}

- (void)testScanListPrefixInvalidNumber
{
	NSString *string = @"  a1. one";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertFalse(b, @"Should not be able to scan list prefix");
	XCTAssertNil(prefix, @"prefix should be nil");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanListPrefixOnlySpaces
{
	NSString *string = @"  ";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *prefix;
	
	BOOL b = [scanner scanMarkdownLineListPrefix:&prefix];
	
	XCTAssertFalse(b, @"Should not be able to scan list prefix");
	XCTAssertNil(prefix, @"prefix should be nil");
	
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

#pragma mark - Marked Range Markers

- (void)_testScanMarkedRangeBeginningsInString:(NSString *)string expectedMarker:(NSString *)expectedMarker
{
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSString *marker;
	BOOL b = [scanner scanMarkdownBeginMarker:&marker];
	
	XCTAssertTrue(b, @"Should be able to scan opening marker");
	XCTAssertEqualObjects(expectedMarker, marker, @"Incorrect Marker scanned");
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
	
	XCTAssertFalse(b, @"Should not be able to scan formatted text with newline in it");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

#pragma mark - Link Scanning

- (void)testScanImage
{
	NSString *string = @"![Alt text](/path/to/img.jpg \"Optional title\")";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	XCTAssertTrue(b, @"Should be able to scan opening marker");
	XCTAssertEqualObjects(attributes[@"src"], @"/path/to/img.jpg", @"Incorrect SRC");
	XCTAssertEqualObjects(attributes[@"alt"], @"Alt text", @"Incorrect ALT");
	XCTAssertEqualObjects(attributes[@"title"], @"Optional title", @"Incorrect TITLE");
}

- (void)testScanImageNoLink
{
	NSString *string = @"![Alt text]()";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	XCTAssertFalse(b, @"Should not be able to scan image");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanImageNoClosingBracketAfterLink
{
	NSString *string = @"![Alt text](http://foo.com";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	XCTAssertFalse(b, @"Should not be able to scan image");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanImageEmptyReference
{
	NSString *string = @"![Alt][]";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:nil];
	
	XCTAssertFalse(b, @"Should not be able to scan image");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanImageExistingReferenceButMissingClosingBracket
{
	NSString *string = @"![Alt][";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	BOOL b = [scanner scanMarkdownImageAttributes:&attributes references:@{@"alt":@{@"href": @"http://foo.com"}}];
	
	XCTAssertFalse(b, @"Should not be able to scan image");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}

- (void)testScanLinkExistingReferenceButMissingClosingBracket
{
	NSString *string = @"[Alt][";
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	NSString *enclosed;
	BOOL b = [scanner scanMarkdownHyperlinkAttributes:&attributes enclosedString:&enclosed references:@{@"alt":@{@"href": @"http://foo.com"}}];
	
	XCTAssertFalse(b, @"Should not be able to scan image");
	XCTAssertEqual(scanner.scanLocation, (NSUInteger)0, @"Scan location should not be moved");
}
- (void)testEmptyLink
{
	NSString *string = @"[Link]()";

	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = nil;
	
	NSDictionary *attributes;
	NSString *enclosed;
	BOOL b = [scanner scanMarkdownHyperlinkAttributes:&attributes enclosedString:&enclosed references:nil];
	
	XCTAssertTrue(b, @"Should result in scanned link");
	
	XCTAssertEqualObjects(@"Link", enclosed, @"Wrong enclosed string");
	XCTAssertEqual([attributes count], (NSUInteger)0, @"There should be no attributes");
}

@end
