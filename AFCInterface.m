	/*

	AFCInterface.m
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

// AFCInterface communicates directly with the iPod touch/iPhone device (well,
// through MobileDevice.framework). The AFCDevice class wraps this with nicer methods
// and functionality. 

#import "AFCInterface.h"
#import "MobileDevice.h"

@interface AFCInterface (Private) 
-(NSDictionary *)createDictionaryForAFCDictionary:(struct afc_dictionary *)dict;
@end

@implementation AFCInterface


-(id)initWithAFCConnection:(struct afc_connection *)handle {
	
	if (self = [super init]) {
		afc_handle = handle;
	}
	
	return self;
	
}

-(BOOL)removePath:(NSString *)path {
	return AFCRemovePath(afc_handle, [path UTF8String]) == 0;
}

-(BOOL)renamePath:(NSString *)from to:(NSString *)to {
	return AFCRenamePath(afc_handle, [from UTF8String], 
						 [to UTF8String]) == 0;
}

-(BOOL)createDirectory:(NSString *)path {
	return AFCDirectoryCreate(afc_handle, [path UTF8String]) == 0;
}

-(NSArray *)listFilesInPath:(NSString *)path {
	
	struct afc_directory *hAFCDir;
	
	if (AFCDirectoryOpen(afc_handle, [path UTF8String], &hAFCDir) != 0) {
		[NSException raise:@"" format:@""];
		return nil;
	} else {
	
		NSMutableArray *fileList = [[NSMutableArray alloc] init];
		char *buffer = nil;
		
		do {
			AFCDirectoryRead(afc_handle, hAFCDir, &buffer);
			if (buffer != nil) {
				[fileList addObject:[NSString stringWithCString:buffer]];
			}
		} while (buffer != nil);
		
		AFCDirectoryClose(afc_handle, hAFCDir);
		
		return [fileList autorelease];
		
	}
}

-(BOOL)isDirectoryAtPath:(NSString *)path {
	NSDictionary *dict = [self getAttributesAtPath:path];
	return dict && [[dict valueForKey:@"st_ifmt"] isEqualToString:@"S_IFDIR"];
}


-(BOOL)isFileAtPath:(NSString *)path {
	NSDictionary *dict = [self getAttributesAtPath:path];
	return dict && [[dict valueForKey:@"st_ifmt"] isEqualToString:@"S_IFREG"];

}
	

-(NSDictionary *)getAttributesAtPath:(NSString *)path {
		
	struct afc_dictionary *info;
	
	if (AFCFileInfoOpen(afc_handle, [path UTF8String], &info) != 0) {
		return nil;
	} 
	
	NSDictionary *fileProperties = [self createDictionaryForAFCDictionary:info];
	AFCKeyValueClose(info);
	
	
	return fileProperties;	
}

-(NSDictionary *)getDeviceAttributes {

	struct afc_dictionary *info;
	if (AFCDeviceInfoOpen(afc_handle, &info) != 0) {
		return nil;
	} 
	
	NSDictionary *deviceProperties = [self createDictionaryForAFCDictionary:info];
	AFCKeyValueClose(info);
	
	return deviceProperties;	
}


-(unsigned long long)openFileAtPath:(NSString *)path withMode:(int)mode {

	afc_file_ref rAFC;
	
	int ret = AFCFileRefOpen(afc_handle, [path UTF8String], mode, &rAFC);
	if (ret != 0) {
		NSLog(@"AFCFileRefOpen(%d): %d", mode, ret);
		return 0;
	}
	return rAFC;
}


-(BOOL)closeFile:(unsigned long long)rAFC {
	return AFCFileRefClose(afc_handle, rAFC) == 0;
}


-(NSData *)readFromFile:(unsigned long long)rAFC size:(unsigned int *)size offset:(off_t)offset {

	int ret = AFCFileRefSeek(afc_handle, rAFC, offset, 0);
	
	if (ret != 0) {
		return nil;
	}
   
    char *buffer = malloc(*size);
    unsigned int s = *size;
    
	ret = AFCFileRefRead(afc_handle, rAFC, buffer, &s);
	
	if (ret != 0) {
        //buffer = nil;
        NSLog(@"ret: %d", ret);
		return nil;
	}
    
    *size = s;
    
    NSData *data = [NSData dataWithBytes:buffer length:s];
    
    free(buffer);
    
    //buffer = buf;
    	
	return data;	
}


-(BOOL)writeToFile:(unsigned long long)rAFC data:(const char *)data size:(size_t)size offset:(off_t)offset {
	
	if (size > 0) {
		
		int ret = AFCFileRefSeek(afc_handle, rAFC, offset, 0);
		
		if (ret != 0) {
			return NO;
		}

		ret = AFCFileRefWrite(afc_handle, rAFC, data, (unsigned long)size);
		
		if (ret != 0) {
			return NO;
		}
	}		
		
	// Writing 0 bytes can't fail, really.
	return YES;
}

-(BOOL)setSizeOfFile:(NSString *)path toSize:(off_t)size {

	afc_file_ref rAFC;
	int ret = AFCFileRefOpen(afc_handle, [path UTF8String], 3, &rAFC);
	
	if (ret != 0) {
		return NO;
	}
	
	ret = AFCFileRefSetFileSize(afc_handle, rAFC, size);
	AFCFileRefClose(afc_handle, rAFC);
	
	if (ret != 0) {
		return NO;
	}
	
	return YES;
	
}

-(NSDictionary *)createDictionaryForAFCDictionary:(struct afc_dictionary *)dict {
	
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	char *key, *val;
	
	while ((AFCKeyValueRead(dict, &key, &val) == 0) && key && val) {
		[dictionary setValue:[NSString stringWithCString:val] forKey:[NSString stringWithCString:key]];
	}
	
	return [dictionary autorelease];
	
}
	

	
	


@end
