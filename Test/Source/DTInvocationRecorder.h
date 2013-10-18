//
//  DTInvocationRecorder.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTInvocationRecorder : NSObject

- (void)addProtocol:(Protocol *)protocol;

- (NSArray *)invocationsMatchingSelector:(SEL)selector;

@property (nonatomic, readonly) NSArray *invocations;

@end
