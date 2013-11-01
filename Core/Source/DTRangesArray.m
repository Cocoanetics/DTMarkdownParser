//
//  DTRangeDictionary.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTRangesArray.h"

@implementation DTRangesArray
{
	NSRange *_ranges;
	NSUInteger _count;
	NSUInteger _capacity;
}

- (void)dealloc
{
	free(_ranges);
}

#pragma mark - Enumerating Ranges

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

#pragma mark - Getting Information

- (NSUInteger)count
{
	return _count;
}

#pragma mark - Modifying the Array

- (void)_extendCapacity
{
	if (_capacity)
	{
		_capacity = _capacity*2;
		_ranges = realloc(_ranges, _capacity * sizeof(NSRange));
	}
	else
	{
		_capacity = 100;
		_ranges = malloc(_capacity * sizeof(NSRange));
	}
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

#pragma mark - Finding Ranges

- (NSRange)rangeAtIndex:(NSUInteger)index
{
	NSAssert(index<_count, @"Cannot retrieve index %lu which is outside of number of ranges %lu", (unsigned long)index, (unsigned long)_count);
	
	return _ranges[index];
}

- (NSRange *)_rangeInRangesContainingLocation:(NSUInteger)location
{
	int (^comparator)(const void *, const void *) = ^(const void *locationPtr, const void *rangePtr) {
		
		NSUInteger location = *(NSUInteger *)locationPtr;
		NSRange range = *(NSRange *)rangePtr;
		
		if (location < range.location)
		{
			return -1;
		}
		
		if (location >= NSMaxRange(range))
		{
			return 1;
		}
		
		return 0;
	};
	
	return bsearch_b(&location, _ranges, _count, sizeof(NSRange), comparator);
}


- (NSUInteger)indexOfRangeContainingLocation:(NSUInteger)location
{
	NSRange *found = [self _rangeInRangesContainingLocation:location];
	
	if (found)
	{
		return found - _ranges; // calc index
	}
	
	return NSNotFound;
}

- (NSRange)rangeContainingLocation:(NSUInteger)location
{
	NSRange *found = [self _rangeInRangesContainingLocation:location];
	
	if (found)
	{
		return *found;
	}
	
	return NSMakeRange(NSNotFound, 0);
}

@end
