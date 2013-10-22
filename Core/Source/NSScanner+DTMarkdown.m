//
//  NSScanner+DTMarkdown.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 21.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSScanner+DTMarkdown.h"

@implementation NSScanner (DTMarkdown)

- (BOOL)scanMarkdownHyperlink:(NSString **)URLString title:(NSString **)title
{
	NSUInteger startPos = self.scanLocation;

	NSString *hrefString;
	
	if (![self scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&hrefString])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	NSUInteger posAfterHREF = self.scanLocation;
	
	NSCharacterSet *quoteChars = [NSCharacterSet characterSetWithCharactersInString:@"'\"("];
	
	NSString *quote;
	NSString *quotedTitle;
	
	// optional spaces
	[self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
	
	if ([self scanCharactersFromSet:quoteChars intoString:&quote])
	{
		if ([quote hasPrefix:@"'"])
		{
			if ([self scanUpToString:@"'" intoString:&quotedTitle])
			{
				if (![self scanString:@"'" intoString:NULL])
				{
					quotedTitle = nil;
					self.scanLocation = posAfterHREF;
				}
			}
		}
		else if ([quote hasPrefix:@"\""])
		{
			if ([self scanUpToString:@"\"" intoString:&quotedTitle])
			{
				if (![self scanString:@"\"" intoString:NULL])
				{
					quotedTitle = nil;
					self.scanLocation = posAfterHREF;
				}
			}
		}
		else if ([quote hasPrefix:@"("])
		{
			if ([self scanUpToString:@")" intoString:&quotedTitle])
			{
				if (![self scanString:@")" intoString:NULL])
				{
					quotedTitle = nil;
					self.scanLocation = posAfterHREF;
				}
			}
		}
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
	
	NSString *scannedURLString;
	NSString *scannedTitle;
	
	if (![self scanMarkdownHyperlink:&scannedURLString title:&scannedTitle])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	if (reference)
	{
		*reference = refString;
	}
	
	if (URLString)
	{
		*URLString = scannedURLString;
	}
	
	if (title)
	{
		*title = scannedTitle;
	}
	
	return YES;
}

- (BOOL)scanListPrefix:(NSString **)prefix
{
	NSUInteger startPos = self.scanLocation;
	
	// up to 3 spaces
	NSCharacterSet *space = [NSCharacterSet characterSetWithCharactersInString:@" "];
	NSString *spaces;
	
	if ([self scanCharactersFromSet:space intoString:&spaces])
	{
		if ([spaces length]>3)
		{
			self.scanLocation = startPos;
			return NO;
		}
	}
	
	// scan prefix
	NSString *foundPrefix;
	
	if (![self scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&foundPrefix])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	
	// whitespace
	if (![self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	// check if it is a valid prefix
	
	if (![foundPrefix isEqualToString:@"*"])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	if (prefix)
	{
		*prefix = foundPrefix;
	}
	
	return YES;
}

@end
