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
#define SCREEN_HEIGHT 384 // iPhone screen (480) minus dock (96)
#define PAD 10
#define CONTAINER_HEIGHT (SCREEN_HEIGHT + (PAD * 2))
#define SCREEN_X_OFFSET(x) (x * SCREEN_WIDTH) + (PAD * (x + 1))
#define MAX_APP_SCREENS 11

@implementation AppController

@synthesize screenControllers, dockController, numberOfDockApps;

- (void)awakeFromNib {
	[self initialSetup];
	//self.numberOfDockApps = APPS_PER_ROW;
	NSLog(@"AppController is awake");
}

- (void)initialSetup {
	self.screenControllers = [[[NSMutableArray alloc] init] autorelease];
	self.dockController = [[[AppScreenController alloc] init] autorelease];
	dockController.apps = [NSMutableArray array];
	dockController.screen = dockView;
	dockController.appController = self;
	[dockController setScreenAttributes];
}

- (void)dealloc {
	[screenControllers release];
	[dockController release];
	[super dealloc];
}

- (IBAction)addScreen:(id)sender {
	NSRect screenFrame = NSMakeRect(SCREEN_X_OFFSET([screenControllers count]), PAD, SCREEN_WIDTH, SCREEN_HEIGHT);	
	AppScreenController *controller = [[AppScreenController alloc] initWithFrame:screenFrame andController:self];
	[controller setScreenAttributes];
	[screenControllers addObject:controller];
	[scrollViewContent addSubview:[controller screen]];
	[scrollViewContent setFrame:NSMakeRect(0, 0, SCREEN_X_OFFSET([screenControllers count]), CONTAINER_HEIGHT)];
	[controller release];
}

- (IBAction)removeLastScreen:(id)sender {
	if ([[[screenControllers lastObject] apps] count] == 0) {
		[self removeScreenController:[screenControllers lastObject]];
	}
}

- (void)removeScreenController:(AppScreenController *)aScreenController {
	[[aScreenController screen] removeFromSuperview];
	[screenControllers removeObject:aScreenController];
	[scrollViewContent setFrame:NSMakeRect(0, 0, SCREEN_X_OFFSET([screenControllers count]), CONTAINER_HEIGHT)];
}

- (void)reloadScreenAtIndex:(int)screenNum {
	if (screenNum == DOCK) {
		[[dockController screen] reloadData];
	} else if (screenNum < [screenControllers count]) {
		[[[screenControllers objectAtIndex:screenNum] screen] reloadData];
	}
}

- (void)addApp:(iPhoneApp *)anApp toScreen:(int)aScreen atIndex:(int)anIndex {
	if (anApp) {
		// Handle the Dock apps
		if (aScreen == DOCK) {
			[[dockController apps] addObject:anApp];
		} else {
			AppScreenController *screenController = [screenControllers objectAtIndex:aScreen];
			if (!screenController) {
				[self addScreen:nil];
				screenController = [screenControllers objectAtIndex:aScreen];
			}
			[[screenController apps] addObject:anApp];
		}
	}
}

- (void)handleOverflowForAppScreen:(AppScreenController *)appScreen {
	NSArray *overflowingApps = [appScreen overflowingApps];
	AppScreenController *destinationScreen = nil;
	if ([appScreen isEqual:[screenControllers lastObject]]) {
		[self addScreen:nil];
		destinationScreen = [screenControllers lastObject];
		
	} else {
		int appScreenNumber = ([screenControllers indexOfObject:appScreen] + 1);
		destinationScreen = [screenControllers objectAtIndex:appScreenNumber];
	}
	
	// Do nothing if source and destination are the same at this point
	if (![appScreen isEqual:destinationScreen]) {
		[appScreen removeApps:overflowingApps];
		[destinationScreen insertApps:overflowingApps atIndex:0];
	}
}

- (IBAction)promptWriteAppsToSpringboard:(id)sender {
	// First, prompt the user to backup their existing springboard plist
	NSBeginAlertSheet(@"Do you want to make a backup of your springboard?", 
					  @"Yes!", @"No, I'm reckless", nil, 
					  appWindow, 
					  self, 
					  @selector(sheetDidEndShouldBackup:returnCode:contextInfo:), 
					  nil, 
					  nil, 
					  @"You really should backup your springboard. This is beta software!");
}


# pragma mark -
# pragma mark Sheet methods
- (void)sheetDidEndShouldBackup: (NSWindow *)sheet
					 returnCode: (NSInteger)returnCode
					contextInfo: (void *)contextInfo
{
    
	if (returnCode == NSAlertDefaultReturn) {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		
		int result = [savePanel runModalForDirectory:nil file:@"springboard.plist"];
		
		if (result == NSOKButton) {
			[phoneController backupSpringBoardToFilePath:[savePanel filename]];
			[phoneController writeAppsToSpringBoard];
		}
	} else {
		[phoneController writeAppsToSpringBoard];
	}
}

@end
