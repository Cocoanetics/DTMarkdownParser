//
//  JXRangeArray.h
//
//  Created by Jan on 30.10.13.
//  Copyright (c) 2006-2007 Christopher J. W. Lloyd
//  Copyright (c) 2013 Cocoanetics. Some rights reserved.
//
//  Based on NSRangeArray from cocotron
//  http://www.cocotron.org
//

/*
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

@interface JXRangeArray : NSObject {
	NSUInteger _count, _capacity;
	NSRange  *_ranges;
}

- (instancetype)init;
- (instancetype)initWithRanges:(const NSRange *)ranges count:(NSUInteger)count;

- (NSUInteger)count;
- (NSRange)rangeAtIndex:(NSUInteger)idx;

- (void)addRange:(NSRange)range;
- (void)insertRange:(NSRange)range atIndex:(NSUInteger)idx;

- (void)removeLastRange;
- (void)removeRangeAtIndex:(NSUInteger)idx;
- (void)replaceRangeAtIndex:(NSUInteger)idx withRange:(NSRange)range;

- (void)removeAllRanges;

- (NSRange *)ranges NS_RETURNS_INNER_POINTER; 

- (void)enumerateRangesUsingBlock:(void (^)(NSRange range, NSUInteger idx, BOOL *stop))block;
- (void)enumerateRangesWithOptions:(NSEnumerationOptions)opts
						usingBlock:(void (^)(NSRange range, NSUInteger idx, BOOL *stop))block; // Supports NSEnumerationReverse.

- (NSRange)rangeContainingIndex:(NSUInteger)idx;
- (NSRange)rangeContainingIndex:(NSUInteger)idx foundArrayIndex:(NSUInteger *)foundRangeIndex;
- (NSUInteger)arrayIndexForRangeContainingIndex:(NSUInteger)idx;

- (NSString *)descriptionWithLocale:(id)locale;
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;

@end
