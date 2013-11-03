//
//  DTMarkdownParser.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTWeakSupport.h"

@class DTMarkdownParser;

/**
 The DTMarkdownParserDelegate protocol defines the optional methods implemented by delegates of DTMarkdownParser objects.
 */

@protocol DTMarkdownParserDelegate <NSObject>

@optional
/*
 Sent by the parser object to the delegate when it begins parsing a document.
 @param A parser object.
 */
- (void)parserDidStartDocument:(DTMarkdownParser *)parser;

/*
 Sent by the parser object to the delegate when it has successfully completed parsing.
 @param A parser object.
 */
- (void)parserDidEndDocument:(DTMarkdownParser *)parser;

/*
 Sent by a parser object to provide its delegate with a string representing all or part of the characters of the current element.
 @param parser A parser object.
 @param string Found string content
 */
- (void)parser:(DTMarkdownParser *)parser foundCharacters:(NSString *)string;

/*
 Sent by a parser object to its delegate when it encounters a start tag for a given element.
 @param parser A parser object.
 @param elementName A string that is the name of an element (in its start tag).
 @param attributeDict A dictionary that contains any attributes associated with the element. Keys are the names of attributes, and values are attribute values.
 */
- (void)parser:(DTMarkdownParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;

/*
 Sent by a parser object to its delegate when it encounters a start tag for a given element.
 @param parser A parser object.
 @param elementName A string that is the name of an element (in its end tag).
 */
- (void)parser:(DTMarkdownParser *)parser didEndElement:(NSString *)elementName;

@end

/**
 Parsing options for DTMarkdownParser
 */
typedef NS_ENUM(NSUInteger, DTMarkdownParserOptions)
{
	/**
	 Use GitHub-style for line breaks, one is a BR, two is a P
	 */
	DTMarkdownParserOptionGitHubLineBreaks = 1<<0
};

/**
 DTMarkdownParser is an event-based parser for Markdown. It is modeled after `NSXMLParser` and events can be used to generate HTML or other structured output formats.
 */

@interface DTMarkdownParser : NSObject

/**
 @name Creating a Parser
 */

- (instancetype)initWithString:(NSString *)string options:(DTMarkdownParserOptions)options;

/**
 @name Parsing
 */

/**
 Parsing Delegate
 */
@property (nonatomic, DT_WEAK_PROPERTY) id <DTMarkdownParserDelegate> delegate;

/**
 Starts the event-driven parsing operation.
 @returns `YES` if parsing is successful and `NO` in there is an error or if the parsing operation is aborted.
 */
- (BOOL)parse;

@end
