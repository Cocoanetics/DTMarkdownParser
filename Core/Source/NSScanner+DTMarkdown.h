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
- (BOOL)scanListPrefix:(NSString **)prefix;

@end
