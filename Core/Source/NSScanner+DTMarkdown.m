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
	static NSCharacterSet *hrefTerminatorSet = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		NSMutableCharacterSet *tmpSet = [NSMutableCharacterSet whitespaceCharacterSet];
		[tmpSet addCharactersInString:@")'\"("];
		hrefTerminatorSet = [tmpSet copy];
	});
	
	
	NSUInteger startPos = self.scanLocation;
	
	NSString *hrefString;
	
	if (![self scanUpToCharactersFromSet:hrefTerminatorSet intoString:&hrefString])
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

- (BOOL)scanMarkdownLineListPrefix:(NSString **)prefix
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
	
	if ([foundPrefix hasSuffix:@"."])
	{
		NSString *numberPart = [foundPrefix substringToIndex:[foundPrefix length]-1];
		
		// can only be digits before the period
		if ([[numberPart stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] length])
		{
			self.scanLocation = startPos;
			return NO;
		}
	}
	else if (![foundPrefix isEqualToString:@"*"] && ![foundPrefix isEqualToString:@"+"] && ![foundPrefix isEqualToString:@"-"])
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

- (BOOL)scanMarkdownBeginMarker:(NSString **)beginMarker
{
	static NSCharacterSet *markerChars = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		markerChars = [NSCharacterSet characterSetWithCharactersInString:@"*_~`"];
	});
	
	NSUInteger startPos = self.scanLocation;
	
	NSString *marker;
	
	if (![self scanCharactersFromSet:markerChars intoString:&marker])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	// determine effective marker
	NSString *effectiveMarker = nil;
	
	if ([marker hasPrefix:@"**"])
	{
		effectiveMarker = @"**";
	}
	else if ([marker hasPrefix:@"*"])
	{
		effectiveMarker = @"*";
	}
	else if ([marker hasPrefix:@"__"])
	{
		effectiveMarker = @"__";
	}
	else if ([marker hasPrefix:@"_"])
	{
		effectiveMarker = @"_";
	}
	else if ([marker hasPrefix:@"~~"])
	{
		effectiveMarker = @"~~";
	}
	else if ([marker hasPrefix:@"`"])
	{
		effectiveMarker = @"`";
	}
	
	NSAssert(effectiveMarker, @"Should always have an effective marker here");

	self.scanLocation = startPos + [effectiveMarker length];
	
	// there cannot be a space after a beginning marker
	if ([self scanString:@" " intoString:NULL])
	{
		self.scanLocation = startPos;
		return NO;
	}

	if (marker)
	{
		*beginMarker = effectiveMarker;
	}
	
	self.scanLocation = startPos + [effectiveMarker length];
	
	return YES;
}

- (BOOL)scanMarkdownImageAttributes:(NSDictionary **)attributes references:(NSDictionary *)references
{
	NSUInteger startPos = self.scanLocation;
	
	if (![self scanString:@"![" intoString:NULL])
	{
		return NO;
	}
	
	// alt text never contains extra characters
	
	NSString *altText = nil;
	
	// consider alt text optional
	[self scanUpToString:@"]" intoString:&altText];
	
	// expect closing square bracket
	if (![self scanString:@"]" intoString:NULL])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	// skip whitespace
	[self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
	
	NSString *hrefString;
	NSString *title;
	
	// expect opening round or square bracket
	if ([self scanString:@"(" intoString:NULL])
	{
		// scan image hyperlink and optional title
		
		if (![self scanMarkdownHyperlink:&hrefString title:&title])
		{
			self.scanLocation = startPos;
			return NO;
		}
		
		// skip whitespace
		[self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
		
		// expect closing round bracket
		if (![self scanString:@")" intoString:NULL])
		{
			self.scanLocation = startPos;
			return NO;
		}
	}
	else if ([self scanString:@"[" intoString:NULL])
	{
		// scan id
		
		NSString *refId;
		
		if (![self scanUpToString:@"]" intoString:&refId])
		{
			refId = [altText lowercaseString];
		}
		
		NSDictionary *reference = references[[refId lowercaseString]];
		
		if (!reference)
		{
			self.scanLocation = startPos;
			return NO;
		}
		
		// transfer from reference
		title = reference[@"title"];
		hrefString = reference[@"href"];
		
		// expect closing round bracket
		if (![self scanString:@"]" intoString:NULL])
		{
			self.scanLocation = startPos;
			return NO;
		}
	}
	
	if (attributes)
	{
		NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
		
		if (hrefString)
		{
			tmpDict[@"src"] = hrefString;
		}
		
		if (title)
		{
			tmpDict[@"title"] = title;
		}
		
		if (altText)
		{
			tmpDict[@"alt"] = altText;
		}
		
		*attributes = [tmpDict copy];
	}
	
	return YES;
}


- (BOOL)_scanMarkdownTextEnclosedByHyperlink:(NSString **)enclosedText
{
	NSMutableString *tmpString = [NSMutableString string];
	
	NSCharacterSet *stopChars = [NSCharacterSet characterSetWithCharactersInString:@"![]"];
	
	while (![self isAtEnd])
	{
		NSString *part;
		
		if ([self scanUpToCharactersFromSet:stopChars intoString:&part])
		{
			[tmpString appendString:part];
		}
		
		// skip image
		NSUInteger posBeforeImage = self.scanLocation;
		
		if ([self scanMarkdownImageAttributes:NULL references:nil])
		{
			// append image markdown
			NSRange imgRange = NSMakeRange(posBeforeImage, self.scanLocation-posBeforeImage);
			[tmpString appendString:[self.string substringWithRange:imgRange]];
		}
		
		if ([self scanString:@"]" intoString:NULL])
		{
			self.scanLocation --;
			break;
		}
	}
	
	if (![tmpString length])
	{
		return NO;
	}
	
	if (enclosedText)
	{
		*enclosedText = [tmpString copy];
	}
	
	return YES;
}


- (BOOL)scanMarkdownHyperlinkAttributes:(NSDictionary **)attributes enclosedString:(NSString **)encosedString references:(NSDictionary *)references
{
	NSUInteger startPos = self.scanLocation;
	BOOL isSimpleHREF;
	NSString *closingMarker;
	NSString *enclosedPart;
	
	static NSDataDetector *detector = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
	});
	
	if ([self scanString:@"<" intoString:NULL])
	{
		isSimpleHREF = YES;
		closingMarker = @">";
		
		// scan enclosed part, can only be a href
		[self scanUpToString:closingMarker intoString:&enclosedPart];
	}
	else if ([self scanString:@"[" intoString:NULL])
	{
		isSimpleHREF = NO;
		closingMarker = @"]";
		
		// scan enclosed part, can contain images
		[self _scanMarkdownTextEnclosedByHyperlink:&enclosedPart];
	}
	else
	{
		return NO;
	}
	
	NSString *hrefString;
	NSString *title;
	
	
	// expect closing marker
	if (![self scanString:closingMarker intoString:NULL])
	{
		self.scanLocation = startPos;
		return NO;
	}
	
	if (isSimpleHREF)
	{
		NSArray *links = [detector matchesInString:enclosedPart options:0 range:NSMakeRange(0, [enclosedPart length])];
		
		NSURL *URL = nil;
		
		if ([links count])
		{
			URL = [links[0] URL];
		}

		if (!URL)
		{
			URL = [NSURL URLWithString:enclosedPart];
		}
		
		if (URL)
		{
			hrefString = [URL absoluteString];
		}
		
		if (!URL)
		{
			self.scanLocation = startPos;
			return NO;
		}
	}
	else
	{
		// skip whitespace
		[self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
		
		// expect opening round or square bracket
		if ([self scanString:@"(" intoString:NULL])
		{
			// we allow empty href and title
			[self scanMarkdownHyperlink:&hrefString title:&title];
			
			// skip whitespace
			[self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
			
			// expect closing round bracket
			if (![self scanString:@")" intoString:NULL])
			{
				self.scanLocation = startPos;
				return NO;
			}
		}
		else if ([self scanString:@"[" intoString:NULL])
		{
			// scan id
			
			NSString *refId;
			
			if (![self scanUpToString:@"]" intoString:&refId])
			{
				refId = [enclosedPart lowercaseString];
			}
			
			NSDictionary *reference = references[[refId lowercaseString]];
			
			if (!reference)
			{
				self.scanLocation = startPos;
				return NO;
			}
			
			// transfer from reference
			title = reference[@"title"];
			hrefString = reference[@"href"];
			
			// expect closing round bracket
			if (![self scanString:@"]" intoString:NULL])
			{
				self.scanLocation = startPos;
				return NO;
			}
		}
		else
		{
			// no [ or (
			self.scanLocation = startPos;
			return NO;
		}
	}

	if (attributes)
	{
		NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
		
		if (hrefString)
		{
			tmpDict[@"href"] = hrefString;
		}
		
		if (title)
		{
			tmpDict[@"title"] = title;
		}
		
		*attributes = [tmpDict copy];
	}
	
	if (encosedString)
	{
		*encosedString = enclosedPart;
	}
	
	return YES;
}

@end
