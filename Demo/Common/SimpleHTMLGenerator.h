//
//  SimpleHTMLGenerator.h
//  DTMarkdownParser
//
//  Created by Jan on 24.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DTMarkdownParser/DTMarkdownParser.h>

@interface SimpleHTMLGenerator : NSObject <DTMarkdownParserDelegate>

@property (readonly) NSMutableString *HTMLString;
@property (readwrite, copy) NSString *title;

- (void)parserDidStartDocument:(DTMarkdownParser *)parser;
- (void)parserDidEndDocument:(DTMarkdownParser *)parser;
- (void)parser:(DTMarkdownParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(DTMarkdownParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;

@end
