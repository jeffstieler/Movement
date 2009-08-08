	/*
	 
	AFCDevice.m
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

// AFCDevice is a wrapper class for the AFCInterface class, providing enhanced
// functionality and hiding away the char* buffers and so on by using more
// Cocoa-friendly classes such as NSData.

#import "AFCDevice.h"



@interface AFCDevice (Private) 

-(BOOL)initializeDevice:(AFCDeviceRef *)dev;
-(struct afc_connection *)openDevice:(AFCDeviceRef *)dev withService:(NSString *)service;

@end

@implementation AFCDevice

-(id)initWithRef:(AFCDeviceRef *)dev {
	
	return [self initWithRef:dev andService:kMediaAFC];

}

-(id)initWithRef:(AFCDeviceRef *)dev andService:(NSString *)svc {
	
	if (self = [super init]) {
		
		// First, initialise the device with the passed am_device structure,
		// then open a connection to it. 
		
		if ([self initializeDevice:dev]) {
			struct afc_connection *connection = [self openDevice:dev withService:svc];
			
			if (connection) {
				
				deviceInterface = [[AFCInterface alloc] initWithAFCConnection:connection];
				
				// Subscribe to the default notification centre for notifications
				// about disconnections. 
				
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnected:) 
															 name:@"AFC_DeviceWasDisconnected" object:nil];
				
			} else {
				[self release];
				return nil;
			}
		} else {
			[self release];
			return nil;
		}
		
	}
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[deviceInterface release];
	[self setDelegate:nil];
	[super dealloc];
}

#pragma mark -
#pragma mark File Reading 

-(NSData *)contentsOfFileAtPath:(NSString *)path {
    
	// Reads an entire file into an NSData object before 
	// returning it. This probably isn't a good idea if you
	// know the file is more than a few Mb. 	
	
    if ([deviceInterface isFileAtPath:path]) {
            
        NSMutableData *data = [[NSMutableData alloc] init];
		
		// Open the file with mode 2 (read only)
        unsigned long long rAFC = [deviceInterface openFileAtPath:path withMode:2];
        unsigned int bufferSize = 256 * 1024; // 256Kb chunks
        unsigned long offset = 0;
        
        if (rAFC != 0) { 
            
            unsigned int size = bufferSize;
            NSData *chunkData = [deviceInterface readFromFile:rAFC size:&size offset:offset];
         
            while (size > 0) {
            
                [data appendData:chunkData];
                offset += size;
                chunkData = [deviceInterface readFromFile:rAFC size:&size offset:offset];
                
            }       
			
            // Make sure the file is closed. 
            [deviceInterface closeFile:rAFC];
        }
        
		
        return [data autorelease];
    
    } else {
        
        return nil;
        
    }    
    
}


-(NSData *)chunkOfFileAtPath:(NSString *)path range:(NSRange)range {
	
	// Reads a subsection of a file into an NSData object before 
	// returning it. Good if you know where some data is in a 
	// bigger file - you don't have to read in the whole thing. 
	
	
	if ([deviceInterface isFileAtPath:path]) {
		
        NSMutableData *data = [[NSMutableData alloc] init];
		
		// Open the file with mode 2 (read only)
        unsigned long long rAFC = [deviceInterface openFileAtPath:path withMode:2];
        unsigned int bufferSize = 256 * 1024; // 256Kb
        unsigned int bytesToRead = range.length;
		
		unsigned long offset = range.location;
        
        if (rAFC != 0) { 
			
			unsigned int size = bufferSize;
			
			if (size > bytesToRead) {
				size = bytesToRead;
			}	
            
            NSData *chunkData = [deviceInterface readFromFile:rAFC size:&size offset:offset];
			
            while (size > 0) {
				
				bytesToRead -= size;
				
                [data appendData:chunkData];
                offset += size;
				
				if (size > bytesToRead) {
					size = bytesToRead;
				}	
				
                chunkData = [deviceInterface readFromFile:rAFC size:&size offset:offset];
                
            }       
            
			// Make sure the file is closed. 
            [deviceInterface closeFile:rAFC];
        }
        
        return [data autorelease];
		
    } else {
        
        return nil;
        
    }    
}


#pragma mark -
#pragma mark File Writing

-(void)createFileAtPath:(NSString *)path withData:(NSData *)data {

	if ([deviceInterface isDirectoryAtPath:[path stringByDeletingLastPathComponent]]) {
		// We can only create the file if the parent directory exists
		
		unsigned long long rAFC = [deviceInterface openFileAtPath:path withMode:3];
		unsigned int bufferSize = 256 * 1024; // 256Kb
		unsigned int bytesToWrite = 0;
		unsigned int offset = 0;
		
		if (rAFC != 0) {
			
			if ([data length] < bufferSize) {
				bufferSize = [data length];
			} 

			bytesToWrite = [data length];
			
			while (bytesToWrite > 0) {
			
				NSData *chunk = [data subdataWithRange:NSMakeRange(offset, bufferSize)];
				
				// Write the chunk
				
				[deviceInterface writeToFile:rAFC data:[chunk bytes] size:bufferSize offset:offset];
				
				offset += bufferSize;
				bytesToWrite -= bufferSize;		
				
				if (bytesToWrite < bufferSize) {
					bufferSize = bytesToWrite;
				} 
				
			}
			
			// Done! 
			
			[deviceInterface closeFile:rAFC];			
			
		}		
	}
}



#pragma mark -
#pragma mark Filesystem

-(void)deleteFileAtPath:(NSString *)path {

	// Delete a file (not a folder) at the given path.
	
	if ([deviceInterface isFileAtPath:path]) {
		[deviceInterface removePath:path];
	}	
}


-(NSArray *)listOfFilesAtPath:(NSString *)path {
    
	// Returns a list of files (not folders) in the given path, which 
	// must be a directory. Checks to make sure that each returned item
	// is actually a file.
	
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    NSArray *contents = [deviceInterface listFilesInPath:path];
    
    NSEnumerator *e = [contents objectEnumerator];
    NSString *fileName;
    
    while (fileName = [e nextObject]) {
    
        if ([fileName isEqualToString:@""] || [fileName isEqualToString:@"."] || [fileName isEqualToString:@".."]) {
          // Do nothing
        } else if ([deviceInterface isFileAtPath:[path stringByAppendingPathComponent:fileName]]) {
            [files addObject:fileName];
        }
    }
    
    return [files autorelease];
}

-(NSArray *)listOfFoldersAtPath:(NSString *)path {
	
	// Returns a list of folders (not files) in the given path, which 
	// must be a directory. Checks to make sure that each returned item
	// is actually a folder.
    
    NSMutableArray *folders = [[NSMutableArray alloc] init];
    
    NSArray *contents = [deviceInterface listFilesInPath:path];
    
    NSEnumerator *e = [contents objectEnumerator];
    NSString *fileName;
    
    while (fileName = [e nextObject]) {
        
        if ([fileName isEqualToString:@""] || [fileName isEqualToString:@"."] || [fileName isEqualToString:@".."]) {
            // Do nothing
        } else if ([deviceInterface isDirectoryAtPath:[path stringByAppendingPathComponent:fileName]]) {
            [folders addObject:fileName];
        }
    }
    
    return [folders autorelease];
    
}

-(AFCInterface *)deviceInterface {
	return deviceInterface;
}

-(void)setDelegate:(id)del {
	[delegate release];
	delegate = [del retain];
}

-(id)delegate {
	return delegate;
}

-(void)setDeviceRef:(AFCDeviceRef *)dev {
	[self setDeviceRef:dev andService:kMediaAFC];
}

-(void)setDeviceRef:(AFCDeviceRef *)dev andService:(NSString *)svc {
	if ([self initializeDevice:dev]) {
		struct afc_connection *connection = [self openDevice:dev withService:svc];
		
		if (connection) {
			[deviceInterface release];
			deviceInterface = [[AFCInterface alloc] initWithAFCConnection:connection];
		}
	}
}
	

-(AFCDeviceRef *)device {
	return device;
}

#pragma mark -
#pragma mark Private Methods


-(void)disconnected:(NSNotification *)notification {
	
	unsigned int disconnectedDev = [[notification object] unsignedIntValue];
	
	if (disconnectedDev == [device device]->device_id) {
		//NSLog(@"I've been disconnected!");
		
		if ([delegate respondsToSelector:@selector(deviceWasDisconnected:)]) {
			[delegate performSelector:@selector(deviceWasDisconnected:) withObject:self];
		}
		
	}
		
	
}


-(BOOL)initializeDevice:(AFCDeviceRef *)dev {
	
	// Connect, pair and start a session to the device.
	
    int ret = AMDeviceConnect([dev device]);
    if (ret != 0) {
		[NSException raise:@"AFCDevice" format:@"AMDeviceConnect failed with error %d", ret];
		return NO;
    }
    if (!AMDeviceIsPaired([dev device])) {
		[NSException raise:@"AFCDevice" format:@"Device pairing failed"];
		return NO;
    }
    ret = AMDeviceValidatePairing([dev device]);
    if (ret != 0) {
		[NSException raise:@"AFCDevice" format:@"AMDeviceValidatePairing failed with error %d", ret];
		return NO;
    }
    ret = AMDeviceStartSession([dev device]);
    if (ret != 0) {
		[NSException raise:@"AFCDevice" format:@"AMDeviceStartSession failed with error %d", ret];
		return NO;
    }
	
	[device release];
	device = [dev retain];
    return YES;
}


-(struct afc_connection *)openDevice:(AFCDeviceRef *)dev withService:(NSString *)service {
	
	// Open a connection to the device. The value of service determines which 
	// service to open - @"com.apple.afc" opens the media service (photos, music, etc)
	// while @"com.apple.afc2" opens the root service, containing the device's applications,
	// etc etc. Note: com.apple.afc2 requires a Jailbroken iPod/iPhone.
	
	
    if (dev == nil) {
		return nil;
    }
	
    struct afc_connection *hAFC;
    
    int ret = AMDeviceStartService([dev device], (CFStringRef)service, &hAFC, NULL);
    if (ret != 0) {
		[NSException raise:@"AFCDevice" format:@"AMDeviceStartService failed with error %d", ret];
		return nil;
    }
    if (hAFC == nil) {  // sanity check
		[NSException raise:@"AFCDevice" format:@"AMDeviceStartService didn't initialise a connection"];
		return nil;
    }
    ret = AFCConnectionOpen(hAFC, 0, &hAFC);
    if (ret != 0) {
		[NSException raise:@"AFCDevice" format:@"AFCConnectionOpen failed with error %d", ret];
		return nil;
    }
    return hAFC;
}


@end
