//
//  DTMarkdownParserDelegateLogger.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
/**
 Logs the parsing delegate callbacks from DTMarkDownParserDelegate.
 */
@interface DTMarkdownParserDelegateLogger : NSObject <DTMarkdownParserDelegate>

/**
 The DTMarkdownParserDelegateLogMessage instances logged by the receiver
 */
@property (nonatomic, readonly) NSArray *log;

@end
