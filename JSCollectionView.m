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
	[object setScreen:browserView];
	[object setScreenAttributesAndDelegate:object];
	[browserView reloadData];
	[newItem setRepresentedObject:object];
	
	return newItem;
}

@end
