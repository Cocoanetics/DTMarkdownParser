//
//  DTMDistributionDelegate.h
//  DTMarkdownParser
//
//  Created by Jan on 25.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DTMarkdownParser/DTMarkdownParser.h>

@interface DTMDistributionDelegate : NSObject <DTMarkdownParserDelegate>

- (void)addDelegate:(id <DTMarkdownParserDelegate>)aDelegate;

@end
