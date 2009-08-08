//
//  iPhoneApp.m
//  iPhoneConnector
//
//  Created by Jeff Stieler on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "iPhoneApp.h"


@implementation iPhoneApp

- (id)initWithIdentifier:(NSString *)aIdentifier 
			 displayName:(NSString *)aName 
					icon:(NSImage *)aIcon { //(NSData *)aIcon {
	if (self = [super init]) {
		self.identifier = aIdentifier;
		self.displayName = aName;
		self.icon = aIcon;
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ [%@] (%d)", displayName, identifier, icon.length];
}

- (void)dealloc {
	[identifier release];
	[displayName release];
	[icon release];
	[super dealloc];
}

#pragma mark -
#pragma mark Required Methods IKImageBrowserItem Informal Protocol
- (NSString *) imageUID
{
	return identifier;
}
- (NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;// IKImageBrowserNSDataRepresentationType;
}
- (id) imageRepresentation
{
	return icon;
}

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol
- (NSString*) imageTitle
{
	return displayName;
}

@synthesize identifier, displayName, icon;

@end
