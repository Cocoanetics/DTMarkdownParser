//
//  DTRangeDictionary.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTRangeDictionary.h"

@implementation DTRangeDictionary
{
	NSRange *_ranges;
	NSUInteger _count;
	NSUInteger _capacity;
}

- (void)dealloc
{
	free(_ranges);
}

- (void)enumerateLineRangesUsingBlock:(void(^)(NSRange range, NSUInteger idx, BOOL *stop))block
{
	NSParameterAssert(block);
	
	for (NSUInteger idx = 0; idx<_count; idx++)
	{
		NSRange range = _ranges[idx];
		BOOL stop = NO;
		
		block(range, idx, &stop);
		
		if (stop)
		{
			break;
		}
	}
}

- (NSUInteger)count
{
	return _count;
}

- (void)_extendCapacity
{
	if (!_capacity)
	{
		_capacity = 100;
		_ranges = calloc(_capacity, sizeof(NSRange));
		return;
	}
	
	// double capacity
	NSUInteger newCapacity = _capacity*2;
	NSRange *newRanges = calloc(newCapacity, sizeof(NSRange));
	
	// copy old
	memcpy(newRanges, _ranges, _capacity);
	
	// move to new block
	free(_ranges);
	_ranges = newRanges;
	_capacity = newCapacity;
}

- (void)addRange:(NSRange)range
{
	if (_count+1>_capacity)
	{
		[self _extendCapacity];
	}
	
	_ranges[_count] = range;
	_count++;
}

- (NSRange)rangeAtIndex:(NSUInteger)index
{
	NSAssert(index<_count, @"Cannot retrieve index %lu which is outside of number of ranges %lu", (unsigned long)index, (unsigned long)_count);
	
	return _ranges[index];
}

- (NSUInteger)indexOfRangeContainingLocation:(NSUInteger)location
{
	
}

- (NSRange)rangeContainingLocation:(NSUInteger)location
{
	
}

@end
