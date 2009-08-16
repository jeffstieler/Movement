/*
 
 AppScreenController.m
 iPhone App Organizer
 
 Copyright (c) 2009 Jeff Stieler
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must, in all cases, contain attribution of 
 Jeff Stieler as the original author of the source code 
 shall be included in all such resulting software products or distributions.
 3. The name of the author may not be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS"' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 
 */

#import "AppScreenController.h"

#define IPHONE_APP_PBOARD_TYPE @"iPhoneApps"

@implementation AppScreenController

@synthesize apps, screen, appController;

- (id)initWithFrame:(NSRect)aFrame andController:(id)aController {
	if (self = [super init]) {
		self.appController = aController;
		self.apps = [NSMutableArray arrayWithCapacity:APPS_PER_SCREEN];
		self.screen = [[[IKImageBrowserView alloc] initWithFrame:aFrame] autorelease];
		[screen setValue:[NSColor blackColor] forKey:IKImageBrowserBackgroundColorKey];
		NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
		[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		[screen setValue:attributes forKey:IKImageBrowserCellsTitleAttributesKey];
		[screen setCellsStyleMask:IKCellsStyleTitled];
		[screen setCellSize:NSMakeSize(50, 50)];
		[screen setAllowsReordering:YES];
		[screen setAnimates:YES];
		[screen setDelegate:self];
		[screen setDataSource:self];
		[screen setDraggingDestinationDelegate:self];
		[screen registerForDraggedTypes:[NSArray arrayWithObject:IPHONE_APP_PBOARD_TYPE]];
	}
	return self;
}

- (void)dealloc {
	[apps release];
	[screen release];
	[super dealloc];
}

- (void)insertApps:(NSArray *)appsToInsert atIndex:(int)index {
	NSEnumerator *appsToInsertReversed = [appsToInsert reverseObjectEnumerator];
	id app;
	while (app = [appsToInsertReversed nextObject]) {
		[apps insertObject:app atIndex:index];
	}
	// Handle overflow if necessary
	if ([apps count] > APPS_PER_SCREEN) {
		[appController handleOverflowForAppScreen:self];
	}
	// Refresh the view
	[screen reloadData];
}

- (void)removeApps:(NSArray *)appsToRemove {
	NSLog(@"my apps: %@", apps);
	NSLog(@"removing: %@", appsToRemove);
	for (id appToRemove in appsToRemove) {
		[apps removeObject:appToRemove];
	}
	NSLog(@"my apps: %@", apps);
	[screen reloadData];
}

- (NSArray *)overflowingApps {
	int numberOfOverflowedApps = ([apps count] - APPS_PER_SCREEN);
	if (numberOfOverflowedApps > 0) {
		NSRange overflowedAppsRange = NSMakeRange(APPS_PER_SCREEN, numberOfOverflowedApps);
		NSIndexSet *overflowedIndexes = [NSIndexSet indexSetWithIndexesInRange:overflowedAppsRange];
		return [apps objectsAtIndexes:overflowedIndexes];
	}
	return nil;
}

#pragma mark - 
#pragma mark Browser Data Source Methods

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{	
	return [apps count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
	return [apps objectAtIndex:index];
}

- (void) imageBrowser:(IKImageBrowserView *) view removeItemsAtIndexes: (NSIndexSet *) indexes
{
    [apps removeObjectsAtIndexes:indexes];
}

- (BOOL) imageBrowser:(IKImageBrowserView *) aBrowser  
   moveItemsAtIndexes: (NSIndexSet *)indexes 
			  toIndex:(unsigned int)destinationIndex
{
	int index;
	NSMutableArray *temporaryArray;
	
	temporaryArray = [[[NSMutableArray alloc] init] autorelease];
	for(index=[indexes lastIndex]; index != NSNotFound;
		index = [indexes indexLessThanIndex:index])
	{
		if (index < destinationIndex)
			destinationIndex --;
		
		id obj = [apps objectAtIndex:index];
		[temporaryArray addObject:obj];
		[apps removeObjectAtIndex:index];
	}
	
	// Insert at the new destination
	int n = [temporaryArray count];
	for(index=0; index < n; index++){
		[apps insertObject:[temporaryArray objectAtIndex:index]
				   atIndex:destinationIndex];
	}
	
	return YES;
}

#pragma mark - 
#pragma mark Browser Dragging Methods

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	int sourceScreenNumber = [[appController screenControllers] indexOfObject:[[sender draggingSource] delegate]];
	int destinationScreenNumber = [[appController screenControllers] indexOfObject:self];
	
	// If the drag would result in overflow back to the sender, do not allow it
	if (((sourceScreenNumber - 1) == destinationScreenNumber) &&
		([apps count] == APPS_PER_SCREEN)) {
		return NO;
	}
	return YES;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender {
    NSData *data = nil;
    NSPasteboard *pasteboard = [sender draggingPasteboard];
	
    if ([[pasteboard types] containsObject:IPHONE_APP_PBOARD_TYPE]) {
		data = [pasteboard dataForType:IPHONE_APP_PBOARD_TYPE];
	}
    if(data) {
		// Add app to destination screen
		NSArray *draggedApps = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		[self insertApps:draggedApps atIndex:[screen indexAtLocationOfDroppedItem]];
		[[[sender draggingSource] delegate] removeApps:draggedApps];
    }
	
    return YES;
}

- (NSUInteger) imageBrowser:(IKImageBrowserView *) aBrowser  
		writeItemsAtIndexes:(NSIndexSet *) itemIndexes 
			   toPasteboard:(NSPasteboard *) pasteboard
{
	NSInteger index;
	for (index = [itemIndexes lastIndex]; index != NSNotFound; index =  
		 [itemIndexes indexLessThanIndex:index])
	{
		NSArray *draggedApps = [apps objectsAtIndexes:itemIndexes];
		[pasteboard declareTypes:[NSArray arrayWithObject:IPHONE_APP_PBOARD_TYPE] owner:nil];
		[pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:draggedApps] forType:IPHONE_APP_PBOARD_TYPE];
	}
	
	return [itemIndexes count];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return (isLocal ? NSDragOperationMove : NSDragOperationNone);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationMove;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationMove;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	
	// If the source view is now empty, remove it
	AppScreenController *sourceController = [[sender draggingSource] delegate];
	if ([[sourceController apps] count] == 0) {
		[sourceController retain];
		[appController removeScreenController:sourceController];
		[sourceController autorelease];
	}
}

@end
