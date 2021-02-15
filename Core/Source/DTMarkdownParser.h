//
//  DTMarkdownParser.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DTMarkdownParser/DTWeakSupport.h>

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
- (void)parserDidStartDocument:(DTMarkdownParser * _Nonnull)parser;

/*
 Sent by the parser object to the delegate when it has successfully completed parsing.
 @param A parser object.
 */
- (void)parserDidEndDocument:(DTMarkdownParser * _Nonnull)parser;

/*
 Sent by a parser object to provide its delegate with a string representing all or part of the characters of the current element.
 @param parser A parser object.
 @param string Found string content
 */
- (void)parser:(DTMarkdownParser * _Nonnull)parser foundCharacters:(NSString * _Nonnull)string;

/*
 Sent by a parser object to its delegate when it encounters a start tag for a given element.
 @param parser A parser object.
 @param elementName A string that is the name of an element (in its start tag).
 @param attributeDict A dictionary that contains any attributes associated with the element. Keys are the names of attributes, and values are attribute values.
 */
- (void)parser:(DTMarkdownParser * _Nonnull)parser didStartElement:(NSString * _Nonnull)elementName attributes:(NSDictionary<NSString *, id> * _Nullable)attributeDict;

/*
 Sent by a parser object to its delegate when it encounters a start tag for a given element.
 @param parser A parser object.
 @param elementName A string that is the name of an element (in its end tag).
 */
- (void)parser:(DTMarkdownParser * _Nonnull)parser didEndElement:(NSString * _Nonnull)elementName;

@end

/**
 Parsing options for DTMarkdownParser
 */
typedef NS_OPTIONS(NSUInteger, DTMarkdownParserOptions)
{
	/**
	 Use GitHub-style for line breaks, one is a BR, two is a P
	 */
	DTMarkdownParserOptionGitHubLineBreaks = 1<<0,
	
	/**
	 With this option an underscore becomes a U. Otherwise it becomes an EM
	 */
	DTMarkdownParserOptionUnderscoreIsUnderline = 1<<1
};

/**
 DTMarkdownParser is an event-based parser for Markdown. It is modeled after `NSXMLParser` and events can be used to generate HTML or other structured output formats.
 */

@interface DTMarkdownParser : NSObject

/**
 @name Creating a Parser
 */

- (instancetype _Nonnull)initWithString:(NSString * _Nonnull)string options:(DTMarkdownParserOptions)options;

/**
 @name Parsing
 */

/**
 Parsing Delegate
 */
@property (nonatomic, DT_WEAK_PROPERTY) id<DTMarkdownParserDelegate> _Nullable delegate;

/**
 Turns automatic URL/link detection on or off. Default value is YES.
 */
@property (nonatomic, assign) BOOL detectURLs;

/**
 Starts the event-driven parsing operation.
 @returns `YES` if parsing is successful and `NO` in there is an error or if the parsing operation is aborted.
 */
- (BOOL)parse;

@end
