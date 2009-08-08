//
//  iPhoneApp.h
//  iPhoneConnector
//
//  Created by Jeff Stieler on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface iPhoneApp : NSObject {
	NSString *displayName;
	NSString *identifier;
	NSData *icon;
}

@property (readwrite, retain)NSString *displayName, *identifier;
@property (readwrite, retain)NSData *icon;

- (id)initWithIdentifier:(NSString *)aIdentifier 
			 displayName:(NSString *)aName 
					icon:(NSImage *)aIcon;//(NSData *)aIcon;

#pragma mark -
#pragma mark Required Methods IKImageBrowserItem Informal Protocol
- (NSString *) imageUID;
- (NSString *) imageRepresentationType;
- (id) imageRepresentation;

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol
- (NSString*) imageTitle;

@end
