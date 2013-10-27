//
//  SimpleTreeGenerator.m
//  DTMarkdownParser
//
//  Created by Jan on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "SimpleTreeGenerator.h"


NSString * const	kSimpleTreeChildren		= @"children";
NSString * const	kSimpleTreeText			= @"text";
NSString * const	kSimpleTreeAttributes	= @"attributes";


@implementation SimpleTreeGenerator {
	NSMutableArray *_nodeStack;
	
	BOOL _verbose;
}


- (id)init;
{
	self = [super init];
	
	if (self) {
		_verbose = NO;
	}
	
	return self;
}


- (void)parserDidStartDocument:(DTMarkdownParser *)parser;
{
	_nodeStack = [NSMutableArray array];
	_nodeTree = [NSMutableArray array];
		
	if (_verbose)  NSLog(@"Markdown Start!");
}

- (void)parserDidEndDocument:(DTMarkdownParser *)parser;
{
	if (_verbose)  NSLog(@"Markdown End!");
	//NSLog(@"%@", _nodeTree);
}

- (void)parser:(DTMarkdownParser *)parser foundCharacters:(NSString *)string;
{
	NSString *quotedString = [NSString stringWithFormat:@"“%@”", string];
	
	if (_verbose)  NSLog(@"%@", quotedString);

	NSMutableDictionary *textNode = [@{
									  kSimpleTreeText: quotedString,
									  kSimpleTreeChildren: [NSMutableArray new]
									  } mutableCopy];
	
	NSMutableArray *children = [self _currentChildren];
	[children addObject:textNode];
	
}

- (void)parser:(DTMarkdownParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
{
	NSString *elementTag = [NSString stringWithFormat:@"<%@>", elementName];
	
	if (_verbose)  NSLog(@"%@", elementTag);
	
	NSMutableDictionary *newNode = [@{
									  kSimpleTreeText: elementTag,
									  kSimpleTreeChildren: [NSMutableArray new]
									  } mutableCopy];
	
	if (attributeDict != nil) {
		newNode[kSimpleTreeAttributes] = attributeDict;
	}
	
	[self _pushNode:newNode];
}

- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;
{
	if (_verbose)  NSLog(@"</%@>", elementName);
	
	[self _popNode];
}


#pragma mark - Generator Helpers

- (void)_pushNode:(NSMutableDictionary *)node
{
	NSMutableArray *children = [self _currentChildren];
	[children addObject:node];
	
	[_nodeStack addObject:node];
}

- (void)_popNode
{
	[_nodeStack removeLastObject];
}

- (NSMutableDictionary *)_currentNode
{
	return [_nodeStack lastObject];
}

- (NSMutableArray *)_currentChildren
{
	NSMutableArray *children;
	
	NSMutableDictionary *currentNode = [self _currentNode];
	if (currentNode != nil) {
		children = currentNode[kSimpleTreeChildren];
	} else {
		children = _nodeTree;
	}
	
	return children;
}


@end
