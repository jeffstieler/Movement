//
//  JSCollectionView.m
//  Nested Collection Views
//
//  Created by Jeff Stieler on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JSCollectionView.h"
#define IPHONE_APP_PBOARD_TYPE @"iPhoneApps"

@implementation JSCollectionView

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
	NSLog(@"newItemForRepresentedObject: %@", object);
	NSCollectionViewItem *newItem = [[self itemPrototype] copy];	
	
	IKImageBrowserView *browserView = [[[newItem view] subviews] objectAtIndex:0];
	/*
	[browserView setValue:[NSColor blackColor] forKey:IKImageBrowserBackgroundColorKey];
	NSDictionary *oldAttributes = [browserView valueForKey:IKImageBrowserCellsTitleAttributesKey];
	NSMutableDictionary *newAttributes = [oldAttributes mutableCopy];
	[newAttributes setObject:[NSFont fontWithName:@"Helvetica" size:11] forKey:NSFontAttributeName];
	[newAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[browserView setValue:newAttributes forKey:IKImageBrowserCellsTitleAttributesKey];
	[newAttributes release];
	[browserView setCellsStyleMask:IKCellsStyleTitled];
	[browserView setCellSize:NSMakeSize(50, 50)];
	[browserView setAllowsReordering:YES];
	[browserView setAllowsMultipleSelection:YES];
	[browserView setAnimates:YES];
	[browserView setDelegate:object];
	[browserView setDataSource:object];
	[browserView setDraggingDestinationDelegate:object];
	[browserView registerForDraggedTypes:[NSArray arrayWithObject:IPHONE_APP_PBOARD_TYPE]];
	*/
	[object setScreen:browserView];
	[object setScreenAttributesAndDelegate:object];
	[browserView reloadData];
	[newItem setRepresentedObject:object];
	
	return newItem;
}

@end
