//
//  Document.m
//  Demo (Mac)
//
//  Created by Oliver Drobnik on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "Document.h"

#import <WebKit/WebKit.h>

NSString * const	MarkdownDocumentType	= @"net.daringfireball.markdown";

@implementation Document {
	IBOutlet NSTextView *	_markdownTextView;
	IBOutlet WebView *		_previewWebView;
	
	NSTextStorage *			_markdownText;
}

- (id)init
{
    self = [super init];
	
    if (self) {
		_markdownText = [[NSTextStorage alloc] init];
    }
	
    return self;
}

- (NSString *)windowNibName
{
	return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	[[_markdownTextView layoutManager] replaceTextStorage:_markdownText];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSData *data = nil;
	
	[_markdownTextView breakUndoCoalescing];
	
	data = [[_markdownText string] dataUsingEncoding:NSUTF8StringEncoding];
	
	return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL result;
	
	NSStringEncoding encoding = NSUTF8StringEncoding;
	
	NSString *markdownString = [[NSString alloc] initWithData:data
													 encoding:encoding];
	if (markdownString != nil) {
		[_markdownText replaceCharactersInRange:NSMakeRange(0, _markdownText.length)
									 withString:markdownString];
		result = YES;
	}
	else {
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain
											code:NSFileReadInapplicableStringEncodingError
										userInfo:nil];
		}
		
		result = NO;
	}
	
	return result;
}

@end
