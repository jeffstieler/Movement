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

@implementation AppScreenController

@synthesize apps, screen;

- (id)initWithFrame:(NSRect)aFrame {
	if (self = [super init]) {
		self.apps = [NSMutableArray arrayWithCapacity:APPS_PER_SCREEN];
		self.screen = [[[IKImageBrowserView alloc] initWithFrame:aFrame] autorelease];
		[screen setCellsStyleMask:IKCellsStyleTitled];
		[screen setCellSize:NSMakeSize(50, 50)];
		[screen setAllowsReordering:YES];
		[screen setAnimates:YES];
		[screen setDelegate:self];
		[screen setDataSource:self];
		[screen setDraggingDestinationDelegate:self];
	}
	return self;
}

- (void)dealloc {
	[apps release];
	[screen release];
	[super dealloc];
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

- (NSUInteger) imageBrowser:(IKImageBrowserView *) aBrowser  
		writeItemsAtIndexes:(NSIndexSet *) itemIndexes 
			   toPasteboard:(NSPasteboard *) pasteboard
{
	NSInteger index;
	
	for (index = [itemIndexes lastIndex]; index != NSNotFound; index =  
		 [itemIndexes indexLessThanIndex:index])
	{
		id app = [apps objectAtIndex:index];
		[pasteboard setData:[app imageRepresentation] forType:NSTIFFPboardType];
	}
	
	return [itemIndexes count];
}

@end
