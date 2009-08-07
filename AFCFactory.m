	/*
	 
	AFCFactory.m
	iPhoneConnection

	 Copyright (c) 2008 KennettNet Software Limited
	 All rights reserved.
	 
	 Redistribution and use in source and binary forms, with or without
	 modification, are permitted provided that the following conditions
	 are met:
	 1. Redistributions of source code must retain the above copyright
	 notice, this list of conditions and the following disclaimer.
	 2. Redistributions in binary form must, in all cases, contain attribution of 
	 KennettNet Software Limited as the original author of the source code 
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

// AFCFActory is a singleton class that listens to connect/disconnect
// notifications from MobileDevice.framework, and informs its delegate
// when these occur. Set the delegate like this:
//
// [[AFCFactory factory] setDelegate:self];
//
// Your delegate class needs to implement -(void)AFCDeviceWasConnected:(AFCDeviceRef *)dev;

#import "AFCFactory.h"
#import "MobileDevice.h"
#import "AFCDeviceRef.h"

@interface AFCFactory (Private)

-(void)notify:(struct am_device_notification_callback_info *)info;

@end

@implementation AFCFactory


#pragma mark -
#pragma mark C -> Obj-C callback delegates

static void notify_callback(struct am_device_notification_callback_info *info, void* arg) {
	AFCFactory* fact = (AFCFactory *)arg;
	[fact notify:info];
	
}

#pragma mark -
#pragma mark Obj-C

static AFCFactory *factory;

+(AFCFactory *)factory {

	if (!factory) {
		factory = [[AFCFactory alloc] init];
	}
	
	return factory;	
}

-(id)init {

	if (factory) {
		[self release];
		return factory;
	} else {
	
		if (self = [super init]) {
			
			struct am_device_notification *notif;
			int ret = AMDeviceNotificationSubscribe(notify_callback, 0, 0, self,
													&notif);
			if (ret != 0) {
				[NSException raise:@"AFCFactory" format:@"AMDeviceNotificationSubscribe failed with error %d", ret];
				
				[self release];
				return nil;
			}
			
		}
		
		return self;		
	}	
}

-(void)dealloc {
	[self setDelegate:nil];
	[super dealloc];
}

-(void)setDelegate:(id)del {

	[delegate release];
	delegate = [del retain];	
}

-(id)delegate {
	return delegate;
}


// Invoked by the static helper method notify_callback
-(void)notify:(struct am_device_notification_callback_info *)info {
	
	if (info->msg == ADNCI_MSG_CONNECTED) {
		
		if ([delegate respondsToSelector:@selector(AFCDeviceWasConnected:)]) {
			[delegate performSelector:@selector(AFCDeviceWasConnected:) 
						   withObject: [[[AFCDeviceRef alloc] initWithAFCDeviceStruct:info->dev] autorelease]];
		}
			
    } else if(info->msg == ADNCI_MSG_DISCONNECTED) {
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AFC_DeviceWasDisconnected" 
															object:[NSNumber numberWithUnsignedInt:info->dev->device_id]];
		
		
		/*if ([delegate respondsToSelector:@selector(AFCDeviceWasDisconnected:)]) {
			[delegate performSelector:@selector(AFCDeviceWasDisconnected:) 
						   withObject: [[[AFCDeviceRef alloc] initWithAFCDeviceStruct:info->dev] autorelease]];
		}*/
		
		
		
    }
    
} 



@end
