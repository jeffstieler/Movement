/*
 
 iPhoneController.m
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

#import "iPhoneController.h"
#import "AFCFactory.h"
#import "PNG Fixer.h"

#define APP_DIR @"/Applications/"
#define USER_APP_DIR @"/User/Applications/"
#define WEBCLIP_DIR @"/User/Library/WebClips/"
#define WEBCLIP_PLIST_PREFIX @"com.apple.webapp"
#define SPRINGBOARD_PLIST @"/User/Library/Preferences/com.apple.springboard.plist"
#define SPRINGBOARD_ICONS_KEY @"iconState"
#define ICONSUPPORT_LAST_USED @"ISLastUsed"
#define ICONSUPPORT_TEST_PATH @"/Library/MobileSubstrate/DynamicLibraries/IconSupport.plist"
#define FCSB_TEST_PATH @"/Library/MobileSubstrate/DynamicLibraries/FCSB.dylib"
#define FCSB_PLIST_PATH @"/User/Library/Preferences/net.r-ch.fcsb.plist"

@implementation iPhoneController

@synthesize possibleIconFileKeys, possibleAppDisplayNameKeys, officialAppDisplayNames, 
			iconListKey, springboard, allAppsOnDevice;

- (void)awakeFromNib {
	[[AFCFactory factory] setDelegate:self];
	
	// Grab official app display name, possible icon/app display name keys from
	// their respective plists in the main bundle
	self.possibleIconFileKeys = (NSArray *)[self contentsOfPlist:@"PossibleIconFileKeys"];
	self.possibleAppDisplayNameKeys = (NSArray *)[self contentsOfPlist:@"PossibleAppDisplayNameKeys"];
	self.officialAppDisplayNames = (NSDictionary *)[self contentsOfPlist:@"OfficialAppDisplayNames"];
}

- (void)dealloc {
	[possibleIconFileKeys release];
	[possibleAppDisplayNameKeys release];
	[officialAppDisplayNames release];
	[allAppsOnDevice release];
	[springboard release];
	[iPhone release];
	[super dealloc];
}


#pragma mark -
#pragma mark iPhone utilities

// Retreive ALL apps (and their paths) on the connected iPhone (user && apple)
- (NSDictionary *)allAppPathsOnDevice {
	if (iPhone) {
		
		NSMutableDictionary *allApps = [NSMutableDictionary dictionaryWithCapacity:2];
		
		// "Official" (and jailbroken) apps are in /Applications/<app name>.app/
		[allApps setObject:[iPhone listOfFoldersAtPath:APP_DIR] forKey:APP_DIR];
		
		NSRange isDotApp;
		NSMutableArray *userApps = [[[NSMutableArray alloc] init] autorelease];
		
		// "Third Party" apps are in /User/Applications/<crazy hash>/<app name>.app/
		for (NSString *folder in [iPhone listOfFoldersAtPath:USER_APP_DIR]) {
			
			NSString *appPath = [NSString pathWithComponents:[NSArray arrayWithObjects:USER_APP_DIR, folder, nil]];
			for (NSString *subFolder in [iPhone listOfFoldersAtPath:appPath]) {

				isDotApp = [subFolder rangeOfString:@".app"];
				if (isDotApp.location != NSNotFound) {
					[userApps addObject:[NSString pathWithComponents:[NSArray arrayWithObjects:folder, subFolder, nil]]];
				}
			}
		}
		[allApps setObject:(NSArray *)userApps forKey:USER_APP_DIR];
		
		// Webclips are /User/Library/WebClips/<crazy hash>.webclip/
		[allApps setObject:[iPhone listOfFoldersAtPath:WEBCLIP_DIR] forKey:WEBCLIP_DIR];
		
		return (NSDictionary *)allApps;
	}
	return nil;
}

- (NSDictionary *)retrieveAllAppsOnDevice {
	NSMutableDictionary *apps = [[[NSMutableDictionary alloc] init] autorelease];
	NSDictionary *allAppPaths = [self allAppPathsOnDevice];
	NSLog(@"all app paths: %@", allAppPaths);
	for (NSString *basePath in allAppPaths) {
		for (NSString *appPath in [allAppPaths objectForKey:basePath]) {
			NSString *fullAppPath = [basePath stringByAppendingString:appPath];
			NSDictionary *appPlist = [self plistContentsForApp:fullAppPath];
			if (appPlist) {
				NSImage *appIcon = [self iconForApp:fullAppPath plistContents:appPlist];
				
				NSString *appIdentifer = [appPlist objectForKey:@"CFBundleIdentifier"];
				// Handle WebClips - no bundle ID
				if (!appIdentifer) {
					NSRange dotRange = [appPath rangeOfString:@".webclip"];
					appIdentifer = [appPath substringToIndex:dotRange.location];
				}
				NSString *appDisplayName = [self displayNameForApp:fullAppPath plistContents:appPlist];
				iPhoneApp *app = [[iPhoneApp alloc] initWithIdentifier:appIdentifer
														   displayName:appDisplayName
																  path:fullAppPath
																  icon:appIcon];
				[apps setObject:app forKey:appIdentifer];
				[app release];
			}
		}
	}
	return [NSDictionary dictionaryWithDictionary:apps];
}

- (void)processApps:(NSArray *)apps forRow:(int)rowNum ofScreen:(int)screenNum {
	for (int appNum = 0; appNum < [apps count]; appNum++) {
		id app = [apps objectAtIndex:appNum];
		if ([app isKindOfClass:[NSNumber class]]) {
			continue;
		}
		NSString *identifier;
		if ([app isKindOfClass:[NSDictionary class]]) {
			identifier = [app valueForKey:@"displayIdentifier"];
		} else {
			identifier = (NSString *)app;
		}

		iPhoneApp *appToAdd = [allAppsOnDevice objectForKey:identifier];
			
		NSRange hypenRange = [identifier rangeOfString:@"-"];
		if (!appToAdd && (hypenRange.location != NSNotFound)) {
			NSString *displayName = [identifier substringFromIndex:(hypenRange.location + 1)];

			// test for webclip (identifier begins with com.apple.webclip)
			BOOL isWebclip = [[identifier substringToIndex:hypenRange.location] isEqualToString:WEBCLIP_PLIST_PREFIX];

			if (isWebclip) {
				[appController addApp:[allAppsOnDevice objectForKey:displayName]
							 toScreen:screenNum];
			} else {

				NSString *oldDisplayName = [NSString stringWithString:displayName];
				if ([officialAppDisplayNames valueForKey:displayName]) {
					displayName = [officialAppDisplayNames valueForKey:displayName];
				}

				NSString *appExecutableName = [identifier substringToIndex:hypenRange.location];
				appToAdd = [allAppsOnDevice objectForKey:appExecutableName];

				NSImage *appIcon = [self iconForApp:[appToAdd path] inContext:oldDisplayName];
				iPhoneApp *newApp = [[iPhoneApp alloc] initWithIdentifier:identifier
															  displayName:displayName
																	 path:appToAdd.path
																	 icon:appIcon];
				[appController addApp:newApp
							 toScreen:screenNum];
				[newApp release];
			}
		} else {
			[appController addApp:appToAdd
						 toScreen:screenNum];
		}
	}				
}

- (NSString *)determineIconListKey {
	// From here on out, Movement will only support the newest version of FCSB, and the iPhone OS 3+
	// As of this comment, that means 1.0 that uses IconSupport
	// also, after checking IconSupport source  -> http://github.com/chpwn/IconSupport/blob/master/IconSupport.m
	// looks like the iconState2 key isn't being used anymore..

	AFCInterface *iPhoneInterface = [iPhone deviceInterface];

	// Test for FCSB and IconSupport
	if ([iPhoneInterface isFileAtPath:FCSB_TEST_PATH] &&
		[iPhoneInterface isFileAtPath:ICONSUPPORT_TEST_PATH] &&
		[iPhoneInterface isFileAtPath:FCSB_PLIST_PATH]) {
	
		NSData *fcsbData = [iPhone contentsOfFileAtPath:FCSB_PLIST_PATH];
		NSDictionary *fcsbPlist = [NSPropertyListSerialization propertyListFromData:fcsbData
																   mutabilityOption:NSPropertyListImmutable
																			 format:nil
																   errorDescription:nil];

		BOOL fcsbEnabled = [(NSNumber *)[fcsbPlist valueForKey:@"Enable"] boolValue];
		NSString *iconSupportPostfix = [self.springboard valueForKey:ICONSUPPORT_LAST_USED];
		BOOL iconSupportEnabled = ([iconSupportPostfix length] > 0);

		if (fcsbEnabled && iconSupportEnabled) {
			return [SPRINGBOARD_ICONS_KEY stringByAppendingString:iconSupportPostfix];
		}
	}
	return SPRINGBOARD_ICONS_KEY;
}


- (void)readAppsFromSpringboard {
	self.springboard = [self springboardFromPhone];
	
	self.iconListKey = [self determineIconListKey];

	NSArray *iconLists = [[[self springboard] objectForKey:iconListKey] objectForKey:@"iconLists"];

	int appsPerRow = [[[iconLists objectAtIndex:0] objectAtIndex:0] count];

	appController.numberOfAppsPerRow = appsPerRow;
	self.allAppsOnDevice = [self retrieveAllAppsOnDevice];
	NSLog(@"all apps: %@", allAppsOnDevice);
	[appController initialSetup];
	for (int screenNum = 0; screenNum < [iconLists count]; screenNum++) {
		
		// Add a screen to the AppController
		[appController addScreen:nil];
		
		NSArray *screenRows = [iconLists objectAtIndex:screenNum];
		
		for (int rowNum = 0; rowNum < [screenRows count]; rowNum++) {
			NSArray *rowApps = [screenRows objectAtIndex:rowNum];
			[self processApps:rowApps forRow:rowNum ofScreen:screenNum];
		}
		[appController reloadScreenAtIndex:screenNum];
	}
	
	// Process all dock apps
	NSArray *dockAppList = [[[self springboard] objectForKey:iconListKey] objectForKey:@"buttonBar"];
	NSArray *dockApps = [dockAppList objectAtIndex:0];
	appController.numberOfDockApps = [dockApps count];
	[self processApps:dockApps forRow:0 ofScreen:DOCK];
	[appController reloadScreenAtIndex:DOCK];

}

- (void)writeAppsToSpringBoard {
	NSLog(@"springboard before moving: %@", springboard);
	NSMutableArray *appScreens = [NSMutableArray array];
	for (AppScreenController *controller in [appController screenControllers]) {
		NSDictionary *screenApps = [controller appsInPlistFormat];
		if (screenApps) {
			[appScreens addObject:screenApps];
		}
	}
	[[springboard objectForKey:iconListKey] setObject:appScreens forKey:@"iconLists"];
	NSDictionary *dockApps = [[appController dockController] appsInPlistFormat];
	[[springboard objectForKey:iconListKey] setObject:dockApps forKey:@"buttonBar"];
	NSString *errorDesc;
	NSLog(@"springboard after moving: %@", springboard);
	NSData *springboardData = [NSPropertyListSerialization dataFromPropertyList:springboard 
																		 format:NSPropertyListXMLFormat_v1_0 
															   errorDescription:&errorDesc];
	if (errorDesc) {
		NSLog(@"Error serializing springboard plist -> NO WRITE!!");
		NSLog(@"%@", errorDesc);
	} else {
		[iPhone createFileAtPath:SPRINGBOARD_PLIST withData:springboardData];
	}
}

- (NSDictionary *)plistContentsForApp:(NSString *)appPath {
	NSString *plistPath = nil;
	NSArray *possibleInfoFiles = [NSArray arrayWithObjects:@"/Info.plist", @"/info.plist", nil];
	for (NSString *possibleFile in possibleInfoFiles) {
		NSString *path = [appPath stringByAppendingPathComponent:possibleFile];
		if ([[iPhone deviceInterface] isFileAtPath:path]) {
			plistPath = path;
		}
	}
	if (plistPath) {
		NSData *plist = [iPhone contentsOfFileAtPath:plistPath];
		return [NSPropertyListSerialization propertyListFromData:plist 
												mutabilityOption:NSPropertyListImmutable
														  format:nil
												errorDescription:nil];
	}
	return nil;
}

- (NSImage *)iconForApp:(NSString *)appPath inContext:(NSString *)appContext {
	NSString *iconNameForContext = [NSString stringWithFormat:@"icon-%@.png", appContext];
	NSString *appIconPath = [appPath stringByAppendingPathComponent:iconNameForContext];
	if ([[iPhone deviceInterface] isFileAtPath:appIconPath]) {
		NSData *fixedData = [PNGFixer fixPNG:[iPhone contentsOfFileAtPath:appIconPath]];
		return [[[NSImage alloc] initWithData:fixedData] autorelease];
	}
	return [NSImage imageNamed:@"sad_mac"];
}

- (NSImage *)iconForApp:(NSString *)appPath plistContents:(NSDictionary *)plistContents {
	NSString *appIconPath = [plistContents valueForKey:@"CFBundleIconFile"];
	if (!appIconPath) {
		for (NSString *iconPath in possibleIconFileKeys) {
			NSString *possibleIconPath = [appPath stringByAppendingPathComponent:iconPath];
			if ([[iPhone deviceInterface] isFileAtPath:possibleIconPath]) {
				appIconPath = iconPath;
				break;
			}
		}
	}
	appIconPath = [appPath stringByAppendingPathComponent:appIconPath];

	NSData *fixedData = [PNGFixer fixPNG:[iPhone contentsOfFileAtPath:appIconPath]];
	return [[[NSImage alloc] initWithData:fixedData] autorelease];
}
			
- (NSString *)displayNameForApp:(NSString *)appPath plistContents:(NSDictionary *)plistContents {
	for (NSString *key in possibleAppDisplayNameKeys) {
		NSString *displayName = [plistContents valueForKey:key];
		if (displayName) {
			if ([officialAppDisplayNames valueForKey:displayName]) {
				displayName = [officialAppDisplayNames valueForKey:displayName];
			}
			return displayName;
		}
	}
	return nil;
}

- (void)backupSpringBoardToFilePath:(NSString *)backupPath {
	[[iPhone contentsOfFileAtPath:SPRINGBOARD_PLIST] writeToFile:backupPath atomically:YES];
}


#pragma mark -
#pragma mark Plist content retrieval helpers

- (id)contentsOfPlist:(NSString *)plistName {
	return [NSPropertyListSerialization
				propertyListFromData:
					[NSData dataWithContentsOfFile:
						[[NSBundle mainBundle]
							pathForResource:plistName
							ofType:@"plist"]]
				mutabilityOption:NSPropertyListImmutable
				format:nil
				errorDescription:nil];
}

// Retreive the SpringBoard plist file
- (NSMutableDictionary *)springboardFromPhone {
	if (iPhone) {
		
		NSData *sbData = [iPhone contentsOfFileAtPath:SPRINGBOARD_PLIST];
		return (NSMutableDictionary *)[NSPropertyListSerialization
										propertyListFromData:sbData
										mutabilityOption:NSPropertyListMutableContainersAndLeaves
										format:nil errorDescription:nil];
	}
	return nil;
}


#pragma mark -
#pragma mark AFC Factory Delegates

-(void)AFCDeviceWasConnected:(AFCDeviceRef *)dev {
	// This is where the action happens - the factory has
	// detected a new iPhone/iPod touch.
	if (iPhone) {

		if ([[[iPhone device] serialNumber] isEqualToString:[dev serialNumber]]) {
			
			// When the same device is reconnected, it seems to have 
			// a different device_id. Therefore, inform our instance 
			// that it's been changed.
			[iPhone setDeviceRef:dev andService:kRootAFC];

			return;
		} 
		
	}
	
	// If it isn't the same device as the previous one, make a new device. 
	[iPhone release];
	iPhone = nil;
	iPhone = [[AFCDevice alloc] initWithRef:dev andService:kRootAFC];

	if (!iPhone) {
		[NSException raise:@"iPhoneController" format:@"Error occurred when trying to init AFC device."];
		
	} else {
		[iPhone setDelegate:self];
	}
	
}

@end
