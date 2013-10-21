//
//  NSString+DTMarkdown.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 21.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DTMarkdown)

/**
 Convert a string into a proper HTML string by converting special characters into HTML entities. For example: an ellipsis `…` is represented by the entity `&hellip;` in order to display it correctly across text encodings.
 @returns A string containing HTML that now uses proper HTML entities.
 */
- (NSString *)stringByAddingHTMLEntities;

@end
