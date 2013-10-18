//
//  DTMarkdownParserDelegateLogMessage.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTMarkdownParserDelegateLogMessage : NSObject

- (instancetype)initWithSelector:(NSString *)selector parameters:(NSArray *)parameters;

@property (nonatomic, readonly) NSString *selector;
@property (nonatomic, readonly) NSArray *parameters;

@end
