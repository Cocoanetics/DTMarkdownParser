//
//  DTRangesArrayTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTRangesArray.h"

@interface DTRangesArrayTest : SenTestCase

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

- (void)testCreate
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	STAssertNotNil(array, @"No array created");
}

- (void)testAdd
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSRange range2 = [array rangeAtIndex:0];
	STAssertEquals(range1, range2, @"Ranges should be equal");
}

- (void)testAddMore
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	[array addRange:NSMakeRange(0, 10)];
	[array addRange:NSMakeRange(10, 10)];
	[array addRange:NSMakeRange(20, 10)];
	
	STAssertEquals(NSMakeRange(0, 10),  [array rangeAtIndex:0], @"Ranges should be equal");
	STAssertEquals(NSMakeRange(10, 10),  [array rangeAtIndex:1], @"Ranges should be equal");
	STAssertEquals(NSMakeRange(20, 10),  [array rangeAtIndex:2], @"Ranges should be equal");
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
	STAssertEquals((NSUInteger)2, index1, @"Wrong index");
	
	NSRange found1 = [array rangeContainingLocation:21];
	STAssertEquals(found1, range3, @"Wrong range");
	
	NSUInteger index2 = [array indexOfRangeContainingLocation:11];
	STAssertEquals((NSUInteger)1, index2, @"Wrong index");

	NSRange found2 = [array rangeContainingLocation:11];
	STAssertEquals(found2, range2, @"Wrong range");
	
	NSUInteger index3 = [array indexOfRangeContainingLocation:3];
	STAssertEquals((NSUInteger)0, index3, @"Wrong index");
	
	NSRange found3 = [array rangeContainingLocation:3];
	STAssertEquals(found3, range1, @"Wrong range");
}

- (void)testInvalidRange
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSUInteger index = [array indexOfRangeContainingLocation:11];
	
	STAssertEquals(index, NSNotFound, @"should not work");
}

- (void)testInvalidLocation
{
	DTRangesArray *array = [[DTRangesArray alloc] init];
	
	NSRange range1 = NSMakeRange(0, 10);
	[array addRange:range1];
	
	NSRange range = [array rangeContainingLocation:11];
	
	STAssertEquals(range, NSMakeRange(NSNotFound, 0), @"should not work");
}

@end
