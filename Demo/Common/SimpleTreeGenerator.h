//
//  SimpleTreeGenerator.h
//  DTMarkdownParser
//
//  Created by Jan on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DTMarkdownParser/DTMarkdownParser.h>

@interface SimpleTreeGenerator : NSObject <DTMarkdownParserDelegate>

@property (readonly) NSMutableArray *nodeTree;

- (void)parserDidStartDocument:(DTMarkdownParser *)parser;
- (void)parserDidEndDocument:(DTMarkdownParser *)parser;
- (void)parser:(DTMarkdownParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(DTMarkdownParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;

@end
