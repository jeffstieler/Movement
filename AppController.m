/*
 
 AppController.m
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

#import "AppController.h"

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 480
#define PAD 10
#define CONTAINER_HEIGHT (SCREEN_HEIGHT + (PAD * 2))
#define SCREEN_X_OFFSET(x) (x * SCREEN_WIDTH) + (PAD * (x + 1))
#define APPS_PER_COLUMN 4
#define APPS_PER_ROW 4

@implementation AppController

@synthesize screenControllers;

- (void)awakeFromNib {
	self.screenControllers = [[[NSMutableArray alloc] init] autorelease];
	NSLog(@"AppController is awake");
}

- (void)dealloc {
	[screenControllers release];
	[super dealloc];
}

- (IBAction)addScreen:(id)sender {
	NSRect screenFrame = NSMakeRect(SCREEN_X_OFFSET([screenControllers count]), PAD, SCREEN_WIDTH, SCREEN_HEIGHT);	
	AppScreenController *controller = [[AppScreenController alloc] initWithFrame:screenFrame];

	[screenControllers addObject:controller];
	[scrollViewContent addSubview:[controller screen]];
	[scrollViewContent setFrame:NSMakeRect(0, 0, SCREEN_X_OFFSET([screenControllers count]), CONTAINER_HEIGHT)];
	[controller release];
}

- (void)addApp:(iPhoneApp *)anApp toScreen:(int)aScreen atIndex:(int)anIndex {
	if (anApp) {
		AppScreenController *screenController = [screenControllers objectAtIndex:aScreen];
		if (!screenController) {
			[self addScreen:nil];
			screenController = [screenControllers objectAtIndex:aScreen];
		}
		//[[screenController apps] replaceObjectAtIndex:anIndex withObject:anApp];
		[[screenController apps] addObject:anApp];// insertObject:anApp atIndex:anIndex];
	}
}

- (IBAction)processAppsOnDevice:(id)sender {
	[phoneController processAppsFromSpringboard];
}

@end
