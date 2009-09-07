/*
 
 iPhoneApp.m
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

#import "iPhoneApp.h"


@implementation iPhoneApp

- (id)init {
	if (self = [super init]) {
		self.identifier = [NSString string];
		self.displayName = [NSString string];
		self.icon = [NSImage imageNamed:@"sad_mac"];
		self.path = [NSString string];
	}
	return self;
}

- (id)initWithIdentifier:(NSString *)aIdentifier 
			 displayName:(NSString *)aName
					path:(NSString *)aPath 
					icon:(NSImage *)aIcon {
	if (self = [super init]) {
		self.identifier = aIdentifier;
		self.displayName = aName;
		self.path = aPath;
		self.icon = aIcon;
	}
	return self;
}

- (NSString *)description {
	return displayName;
}

- (void)dealloc {
	[identifier release];
	[displayName release];
	[icon release];
	[path release];
	[super dealloc];
}

- (BOOL)isEqual:(id)anObject {
	if ([[anObject className] isEqualToString:@"iPhoneApp"]) {
		if ([identifier isEqualToString:[anObject identifier]] &&
			[displayName isEqualToString:[anObject displayName]] ) {
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark NSCoding Methods
- (id)initWithCoder:(NSCoder *)coder {
	[super init];
	self.identifier = [coder decodeObjectForKey:@"identifier"];
	self.displayName = [coder decodeObjectForKey:@"displayName"];
	self.path = [coder decodeObjectForKey:@"path"];
	self.icon = [coder decodeObjectForKey:@"icon"];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:identifier forKey:@"identifier"];
	[coder encodeObject:displayName forKey:@"displayName"];
	[coder encodeObject:path forKey:@"path"];
	[coder encodeObject:icon forKey:@"icon"];
}

#pragma mark -
#pragma mark Required Methods IKImageBrowserItem Informal Protocol
- (NSString *) imageUID
{
	return identifier;
}
- (NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
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

@synthesize identifier, displayName, icon, path;

@end
