//
//  NSScanner+DTMarkdown.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 21.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (DTMarkdown)

// returns yes if there was a hyperlink followed by an optional title
- (BOOL)scanMarkdownHyperlink:(NSString **)URLString title:(NSString **)title;

// returns yes if the current line contained a valid markdown hyperlink reference
- (BOOL)scanMarkdownHyperlinkReferenceLine:(NSString **)reference URLString:(NSString **)URLString title:(NSString **)title;

// returns `YES` if a valid list prefix was scanned
- (BOOL)scanMarkdownLineListPrefix:(NSString **)prefix;

// returns `YES` if a beginning marker of a marked range was scanned
- (BOOL)scanMarkdownBeginMarker:(NSString **)beginMarker;

// returns `YES` if an image was scanned, equivalent to an IMG tag and its attributes src, alt and title. If it is a reference that is found in the references the reference is also used.
- (BOOL)scanMarkdownImageAttributes:(NSDictionary **)attributes references:(NSDictionary *)references;

// returns `YES` if an image was scanned, equivalent to an A tag and its attributes href and title. If it is a reference that is found in the references the reference is also used.
- (BOOL)scanMarkdownHyperlinkAttributes:(NSDictionary **)attributes enclosedString:(NSString **)encosedString references:(NSDictionary *)references;

// returns `YES` if the text has outermost format markers
- (BOOL)scanMarkdownTextBetweenFormatMarkers:(NSString **)text outermostMarker:(NSString **)outermostMarker;

@end
