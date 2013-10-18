//
//  DTMarkdownParser.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@class DTMarkdownParser;


@protocol DTMarkdownParserDelegate <NSObject>

@optional
/*
 Sent by the parser object to the delegate when it begins parsing a document.
 @param A parser object
 */
- (void)parserDidStartDocument:(DTMarkdownParser *)parser;

/*
 Sent by the parser object to the delegate when it has successfully completed parsing.
 @param A parser object
 */
- (void)parserDidEndDocument:(DTMarkdownParser *)parser;

@end



@interface DTMarkdownParser : NSObject

/**
 @name Creating a Parser
 */

- (instancetype)initWithString:(NSString *)string;

/**
 @name Parsing
 */

/**
 Parsing Delegate
 */
@property (nonatomic, weak) id <DTMarkdownParserDelegate> delegate;

/**
 Starts the event-driven parsing operation.
 @returns `YES` if parsing is successful and `NO` in there is an error or if the parsing operation is aborted.
 */
- (BOOL)parse;

@end
