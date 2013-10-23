//
//  TagTreeOutlineController.h
//  DTMarkdownParser
//
//  Created by Jan on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TagTreeOutlineController : NSObject <NSOutlineViewDataSource>

@property (nonatomic, readwrite, strong) NSMutableArray *tagNodes;

@end
