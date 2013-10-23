//
//  Document.m
//  Demo (Mac)
//
//  Created by Oliver Drobnik on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "Document.h"

#import <WebKit/WebKit.h>

#import <DTMarkdownParser/DTMarkdownParser.h>
#import "SimpleTreeGenerator.h"
#import "TagTreeOutlineController.h"

NSString * const	MarkdownDocumentType	= @"net.daringfireball.markdown";

@implementation Document {
	IBOutlet NSTextView *	_markdownTextView;
	IBOutlet WebView *		_previewWebView;
	
	NSFont *				_defaultFont;
	NSTextStorage *			_markdownText;
	
	IBOutlet TagTreeOutlineController *_tagTreeOutlineController;
	NSMutableArray *		_nodeTree;
}

- (id)init
{
    self = [super init];
	
    if (self) {
		_defaultFont = [NSFont fontWithName:@"Menlo"
									   size:18.0];

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
	[_markdownTextView setFont:_defaultFont];
	
	_tagTreeOutlineController.tagNodes = _nodeTree;
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
		
		DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:markdownString
																	options:DTMarkdownParserOptionGitHubLineBreaks];
		
		SimpleTreeGenerator *generator = [SimpleTreeGenerator new];
		parser.delegate = generator;
		
		BOOL couldParse = [parser parse];
		if (couldParse) {
			_nodeTree = generator.nodeTree;
		}
		
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
