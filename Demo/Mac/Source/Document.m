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
#import "DTMDistributionDelegate.h"
#import "SimpleHTMLGenerator.h"
#import "SimpleTreeGenerator.h"
#import "TagTreeOutlineController.h"

NSString * const	MarkdownDocumentType	= @"net.daringfireball.markdown";

const NSTimeInterval kMarkdownDocumentReparseDelay = 0.2;

@implementation Document {
	IBOutlet NSTextView *	_markdownTextView;
	IBOutlet WebView *		_previewWebView;
	
	NSFont *				_defaultFont;
	NSTextStorage *			_markdownText;
	
	IBOutlet TagTreeOutlineController *_tagTreeOutlineController;
	NSMutableArray *		_nodeTree;
	
	IBOutlet NSTextView *	_HTMLTextView;
	NSTextStorage *			_HTMLText;
	
	DTMDistributionDelegate *	_distributionDelegate;
	SimpleTreeGenerator *		_treeGenerator;
	SimpleHTMLGenerator *		_HTMLGenerator;
}

- (id)init
{
    self = [super init];
	
    if (self) {
		_defaultFont = [NSFont fontWithName:@"Menlo"
									   size:18.0];

		_markdownText = [[NSTextStorage alloc] init];

		_HTMLText = [[NSTextStorage alloc] init];
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
	
	[[_HTMLTextView layoutManager] replaceTextStorage:_HTMLText];
	[_HTMLTextView setFont:_defaultFont];

	[self parseMarkdown]; // Necessary, because reparseMarkdown is not triggered by replacing the text storage above.
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

- (void)parseMarkdown
{
	NSString *markdownString = _markdownText.string;
	
	if (_distributionDelegate == nil) {
		_distributionDelegate = [DTMDistributionDelegate new];
		
		_treeGenerator = [SimpleTreeGenerator new];
		[_distributionDelegate addDelegate:_treeGenerator];
		
		_HTMLGenerator = [SimpleHTMLGenerator new];
		[_distributionDelegate addDelegate:_HTMLGenerator];
	}
	
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:markdownString
																options:DTMarkdownParserOptionGitHubLineBreaks];
	
	parser.delegate = _distributionDelegate;
	
	_HTMLGenerator.title = self.displayName;

	BOOL couldParse = [parser parse];
	if (couldParse) {
		_nodeTree = _treeGenerator.nodeTree;

		NSMutableString *HTMLString = _HTMLGenerator.HTMLString;
		[_HTMLText replaceCharactersInRange:NSMakeRange(0, _HTMLText.length)
								 withString:HTMLString];
		[_HTMLTextView setFont:_defaultFont];
	}
	
	_tagTreeOutlineController.tagNodes = _nodeTree;
	
	[[_previewWebView mainFrame] loadHTMLString:_HTMLText.string
										baseURL:[self fileURL]];
}

- (void)textDidChange:(NSNotification *)notification
{
	[self triggerDelayedReparsing];
}

// Based on “Replacing an NSTimer with performSelector:withObject:afterDelay:”
// http://benedictcohen.co.uk/blog/archives/157
- (void)triggerDelayedReparsing
{
	SEL reparseMarkdown = @selector(reparseMarkdown);
	
	// Cancel the previous reparse request.
	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:reparseMarkdown
												   object:nil];
	
	// Reparse after a kMarkdownDocumentReparseDelay delay.
	// If the user enters additional text, reparsing will be cancelled/delayed again by the previous message.
	[self performSelector:reparseMarkdown
			   withObject:nil
			   afterDelay:kMarkdownDocumentReparseDelay];
}

- (void)reparseMarkdown
{
	//NSLog(@"Re-parsing Markdown.");
	[self parseMarkdown];
}

- (IBAction)changePreviewTabIndex:(id)sender;
{
	NSMenuItem *menuItem = sender;
	self.selectedPreviewTabIndex = menuItem.tag;
}

@end
