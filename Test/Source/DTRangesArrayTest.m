//
//  DTRangesArrayTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@import XCTest;
@import DTMarkdownParser;

#import "XCTAssertEqualStructsJX.h"

//
@interface DTRangesArrayTest : XCTestCase

@end

@implementation DTRangesArrayTest

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

- (DTRangesArray *)_rangesArrayWithNumberItems:(NSUInteger)numberItems
{
	DTRangesArray *array = [DTRangesArray new];

	NSRange range = NSMakeRange(0, 13);

	for (NSUInteger i = 0; i<numberItems; i++)
	{
		[array addRange:range];
		
		range.location = NSMaxRange(range);
	}
	
	return array;
}

- (void)testCreate
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	XCTAssertNotNil(array, @"No array created");
}

- (void)testAdd
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSRange range2 = [array rangeAtIndex:0];
	XCTAssertTrue(NSEqualRanges(range1, range2), @"Ranges should be equal");
}

- (void)testAddMore
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	[array addRange:NSMakeRange(0, 10)];
	[array addRange:NSMakeRange(10, 10)];
	[array addRange:NSMakeRange(20, 10)];
	
	XCTAssertEqualStructsJX(NSMakeRange(0, 10),  [array rangeAtIndex:0], @"Ranges should be equal");
	XCTAssertEqualStructsJX(NSMakeRange(10, 10), [array rangeAtIndex:1], @"Ranges should be equal");
	XCTAssertEqualStructsJX(NSMakeRange(20, 10), [array rangeAtIndex:2], @"Ranges should be equal");
}

- (void)testSearchIndex
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSRange range2 = NSMakeRange(10, 10);
	[array addRange:range2];
	
	NSRange range3 = NSMakeRange(20,10);
	[array addRange:range3];
	
	
	NSUInteger index1 = [array indexOfRangeContainingLocation:21];
	XCTAssertEqual((NSUInteger)2, index1, @"Wrong index");
	
	NSRange found1 = [array rangeContainingLocation:21];
	XCTAssertEqualStructsJX(found1, range3, @"Wrong range");
	
	NSUInteger index2 = [array indexOfRangeContainingLocation:11];
	XCTAssertEqual((NSUInteger)1, index2, @"Wrong index");

	NSRange found2 = [array rangeContainingLocation:11];
	XCTAssertEqualStructsJX(found2, range2, @"Wrong range");
	
	NSUInteger index3 = [array indexOfRangeContainingLocation:3];
	XCTAssertEqual((NSUInteger)0, index3, @"Wrong index");
	
	NSRange found3 = [array rangeContainingLocation:3];
	XCTAssertEqualStructsJX(found3, range1, @"Wrong range");
}

- (void)testInvalidRange
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSUInteger index = [array indexOfRangeContainingLocation:11];
	
	XCTAssertEqual(index, (NSUInteger)NSNotFound, @"should not work");
}

- (void)testInvalidLocation
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSRange range = [array rangeContainingLocation:11];
	
	XCTAssertEqualStructsJX(range, NSMakeRange(NSNotFound, 0), @"should not work");
}

- (void)testCapacityExtensionTransfer
{
	DTRangesArray *array = [self _rangesArrayWithNumberItems:100];
	
	NSRange firstRange = [array rangeAtIndex:0];
	NSRange lastRange = [array rangeAtIndex:99];
	lastRange.location = NSMaxRange(lastRange);
	
	[array addRange:lastRange];
	
	NSRange firstRangeAfterExtend = [array rangeAtIndex:0];
	
	XCTAssertEqualStructsJX(firstRange, firstRangeAfterExtend, @"Values were not transferred");
}

- (void)testEnumeration
{
	DTRangesArray *array = [self _rangesArrayWithNumberItems:110];
	
	__block NSUInteger count = 0;
	[array enumerateLineRangesUsingBlock:^(NSRange range, NSUInteger idx, BOOL *stop) {

		NSRange testRange = [array rangeAtIndex:idx];
		
		XCTAssertEqualStructsJX(testRange, range, @"Range not equal");
		count++;
	}];
	
	XCTAssertEqual(count, (NSUInteger)110, @"Wrong count");
}

- (void)testEnumerationStop
{
	DTRangesArray *array = [self _rangesArrayWithNumberItems:110];
	
	__block NSUInteger count = 0;
	[array enumerateLineRangesUsingBlock:^(NSRange range, NSUInteger idx, BOOL *stop) {
		
		NSRange testRange = [array rangeAtIndex:idx];
		
		XCTAssertEqualStructsJX(testRange, range, @"Range not equal");
		count++;
		
		if (idx==9)
		{
			*stop = YES;
		}
	}];
	
	XCTAssertEqual(count, (NSUInteger)10, @"Wrong count");
}

@end
