//
//  DTRangeDictionary.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTRangeDictionary : NSObject

/**
 Enumerates all ranges stored by the receiver
 @param block The block to execute for each line range
 */
- (void)enumerateLineRangesUsingBlock:(void(^)(NSRange range, NSUInteger idx, BOOL *stop))block;

/**
 The number of ranges stored by the receiver
 @returns The count
 */
- (NSUInteger)count;

/**
 Adds a range as the last entry
 @param range The range to add
 */
- (void)addRange:(NSRange)range;

/**
 Returns the range at the given index
 @returns The range
 */
- (NSRange)rangeAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfRangeContainingLocation:(NSUInteger)location;

- (NSRange)rangeContainingLocation:(NSUInteger)location;

@end
