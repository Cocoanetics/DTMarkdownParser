//
//  DTRangeDictionary.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A specialized lookup table to find locations in ranges
 */

@interface DTRangesArray : NSObject

/**
 @name Modifying the Ranges Array
 */

/**
 Adds a range as the last entry
 @param range The range to add
 */
- (void)addRange:(NSRange)range;

/**
 @name Enumerating Ranges
 */

/**
 Enumerates all ranges stored by the receiver
 @param block The block to execute for each line range
 */
- (void)enumerateLineRangesUsingBlock:(void(^)(NSRange range, NSUInteger idx, BOOL *stop))block;


/**
 @name Getting Information
 */

/**
 The number of ranges stored by the receiver
 @returns The count
 */
- (NSUInteger)count;


/**
 @name Finding Ranges
 */

/**
 Returns the range at the given index
 @param index The index to query
 @returns The range
 */
- (NSRange)rangeAtIndex:(NSUInteger)index;

/**
 Returns the index of the range containing the given location
 @param location The location to search for in the ranges
 @returns The index or `NSNotFound` if it is not found
 */
- (NSUInteger)indexOfRangeContainingLocation:(NSUInteger)location;

/**
 Returns the range containing a given location
 @param location The location to search for in the ranges
 @returns The range or `{NSNotFound, 0}` if not found
 */
- (NSRange)rangeContainingLocation:(NSUInteger)location;

@end
