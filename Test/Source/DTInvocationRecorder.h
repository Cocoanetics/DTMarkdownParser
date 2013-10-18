//
//  DTInvocationRecorder.h
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Class for recording all invocations of protocol methods. You can use this for example to record delegate callbacks and then use this information in unit tests.
 */
@interface DTInvocationRecorder : NSObject

/**
 @name Customizing the Recorder
 */

/**
 Adds a protocol to be recorded to the receiver. Afterwards it will act and respond as if implemented all the protocol's methods.
*/
- (void)addProtocol:(Protocol *)protocol;

/**
 Empties the current log of invocations
 */
- (void)clearLog;

/**
 @name Accessing the Log
 */

/**
 The invocations which where recorded since the last -clearLog.
 */
@property (nonatomic, readonly) NSArray *invocations;

/**
 Returns an all invocations which match the given selector
 @param selector The selector to filter for
 */
- (NSArray *)invocationsMatchingSelector:(SEL)selector;

@end
