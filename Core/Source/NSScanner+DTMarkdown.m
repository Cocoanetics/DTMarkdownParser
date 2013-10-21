//
//  NSScanner+DTMarkdown.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 21.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSScanner+DTMarkdown.h"

@implementation NSScanner (DTMarkdown)

- (BOOL)scanMarkdownHyperlinkReferenceLine:(NSString **)reference URLString:(NSString **)URLString title:(NSString **)title
{
	NSUInteger startPos = self.scanLocation;
	
	NSString *whitespace;
	
	// max. 3 spaces
	if ([self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&whitespace])
	{
		if ([whitespace length]>3)
		{
			self.scanLocation = startPos;
			return NO;
		}
	}
	
	// opening [
	if (![self scanString:@"[" intoString:NULL])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	NSString *refString;
	
	// scan ref
	if (![self scanUpToString:@"]:" intoString:&refString])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	// closing bracked of ref
	if (![self scanString:@"]:" intoString:NULL])
	{
		self.scanLocation = startPos;
		return NO;
	}

	// one or more spaces
	if (![self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&whitespace])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	NSString *hrefString;
	
	if (![self scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&hrefString])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	NSCharacterSet *quoteChars = [NSCharacterSet characterSetWithCharactersInString:@"'\"("];
	
	NSString *quote;
	NSString *quotedTitle;
	
	// optional spaces
	if ([self scanUpToCharactersFromSet:quoteChars intoString:&quote])
	{
		
		if ([quote hasPrefix:@"'"])
		{
			if ([self scanUpToString:@"'" intoString:&quotedTitle])
			{
				if (![self scanString:@"'" intoString:NULL])
				{
					self.scanLocation = startPos;
					return NO;
				}
			}
		}
		else if ([quote hasPrefix:@"\""])
		{
			if ([self scanUpToString:@"\"" intoString:&quotedTitle])
			{
				if (![self scanString:@"\"" intoString:NULL])
				{
					self.scanLocation = startPos;
					return NO;
				}
			}
		}
		else if ([quote hasPrefix:@"("])
		{
			if ([self scanUpToString:@")" intoString:&quotedTitle])
			{
				if (![self scanString:@")" intoString:NULL])
				{
					self.scanLocation = startPos;
					return NO;
				}
			}
		}
	}
	
	
	if (reference)
	{
		*reference = refString;
	}
	
	if (URLString)
	{
		*URLString = hrefString;
	}
	
	if (title)
	{
		*title = quotedTitle;
	}
	
	return YES;
}

@end