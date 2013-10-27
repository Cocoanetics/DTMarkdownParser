//
//  TagTreeOutlineController.m
//  DTMarkdownParser
//
//  Created by Jan on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "TagTreeOutlineController.h"

#import "SimpleTreeGenerator.h"

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
	return (item == nil) ? [_tagNodes count] : [(NSDictionary *)item[kSimpleTreeChildren] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return (item == nil) ? NO : ([(NSDictionary *)item[kSimpleTreeChildren] count] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)childIndex ofItem:(id)item
{
	return (item == nil) ? [_tagNodes objectAtIndex:childIndex] : [(NSArray *)((NSDictionary *)item[kSimpleTreeChildren]) objectAtIndex:childIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSDictionary *dict = item;
	NSString *text = dict[kSimpleTreeText];
	
	return text;
}


#pragma mark ---- Delegate methods ----

- (NSString *)outlineView:(NSOutlineView *)outlineView
		   toolTipForCell:(NSCell *)cell
					 rect:(NSRectPointer)rect
			  tableColumn:(NSTableColumn *)tableColumn
					 item:(id)item
			mouseLocation:(NSPoint)mouseLocation
{
	NSDictionary *dict = item;
	
	NSDictionary *attributesDict = dict[kSimpleTreeAttributes];
	if (attributesDict != nil) {
		NSString *text = [attributesDict description];
		return text;
	}
	else {
		return nil;
	}
	
}

@end
