//
// Copyright (c) 2016 Jan Weiß. All rights reserved.
//
// Copyright (c) 2013-2015 Apple Inc. All rights reserved.
//
// Copyright (c) 1997-2005, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the following license:
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// (1) Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// 
// (2) Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation 
// and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL Sente SA OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Note: this license is equivalent to the FreeBSD license.
// 
// This notice may not be removed from this file.


#pragma once


#define _JXXCTPrimitiveAssertEqualStructs(test, expression1, expressionStr1, expression2, expressionStr2, ...) \
({ \
    @try { \
        __typeof__(expression1) expressionValue1 = (expression1); \
        __typeof__(expression2) expressionValue2 = (expression2); \
        NSValue *expressionBox1 = [NSValue value:&expressionValue1 withObjCType:@encode(__typeof__(expression1))]; \
        NSValue *expressionBox2 = [NSValue value:&expressionValue2 withObjCType:@encode(__typeof__(expression2))]; \
        float aNaN = NAN; \
        NSValue *aNaNencoded = [NSValue value:&aNaN withObjCType:@encode(__typeof__(aNaN))]; \
        if ([expressionBox1 isEqualToValue:aNaNencoded] || [expressionBox2 isEqualToValue:aNaNencoded] || ![expressionBox1 isEqualToValue:expressionBox2]) { \
            _XCTRegisterFailure(test, _XCTFailureDescription(_XCTAssertion_Equal, 0, expressionStr1, expressionStr2, _XCTDescriptionForValue(expressionBox1), _XCTDescriptionForValue(expressionBox2)), __VA_ARGS__); \
        } \
    } \
    @catch (_XCTestCaseInterruptionException *interruption) { [interruption raise]; } \
    @catch (NSException *exception) { \
        _XCTRegisterFailure(test, _XCTFailureDescription(_XCTAssertion_Equal, 1, expressionStr1, expressionStr2, [exception reason]), __VA_ARGS__); \
    } \
    @catch (...) { \
        _XCTRegisterFailure(test, _XCTFailureDescription(_XCTAssertion_Equal, 2, expressionStr1, expressionStr2), __VA_ARGS__); \
    } \
})

/*!
 * @define XCTAssertEqualStructsJX(expression1, expression2, ...)
 * Generates a failure when ((\a expression1) != (\a expression2)). This test is for C scalars, structs and unions. Scalars may have to be cast.
 * @param expression1 The first argument.
 * @param expression2 The second argument.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define XCTAssertEqualStructsJX(expression1, expression2, ...) \
    _JXXCTPrimitiveAssertEqualStructs(self, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)

