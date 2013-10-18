//
//  DTMarkdownParserDelegateLogMessage.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParserDelegateLogMessage.h"

@implementation DTMarkdownParserDelegateLogMessage
{
	NSString * _selector;
	NSArray *_parameters;
}

- (instancetype)initWithSelector:(NSString *)selector parameters:(NSArray *)parameters
{
	self = [super init];
	
	if (self)
	{
		_selector = [selector copy];
		_parameters = [parameters copy];
	}
	
	return self;
}

- (void)dealloc
{
	NSLog(@"%@", _parameters);
}

@end
