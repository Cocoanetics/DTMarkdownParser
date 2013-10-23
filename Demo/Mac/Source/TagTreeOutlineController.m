//
//  TagTreeOutlineController.m
//  DTMarkdownParser
//
//  Created by Jan on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "TagTreeOutlineController.h"

@implementation TagTreeOutlineController {
	IBOutlet NSOutlineView *_outlineView;
}

- (void)setTagNodes:(NSMutableArray *)value {
	if (_tagNodes != value) {
		_tagNodes = value;
		if (_tagNodes != nil) {
			[_outlineView reloadData];
			[_outlineView expandItem:nil expandChildren:YES];
		}
	}
}

- (id)init
{
	self = [super init];
	
	if (self) {
		_tagNodes = [NSMutableArray array];
	}
	
	return self;
}


#pragma mark ---- Data Source methods ----

- (void)outlineView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	return;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return (item == nil) ? [_tagNodes count] : [(NSDictionary *)item[@"children"] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return (item == nil) ? NO : ([(NSDictionary *)item[@"children"] count] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)childIndex ofItem:(id)item
{
	return (item == nil) ? [_tagNodes objectAtIndex:childIndex] : [(NSArray *)((NSDictionary *)item[@"children"]) objectAtIndex:childIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSDictionary *dict = item;
	NSString *text = dict[@"text"];
	
	return text;
}

@end
