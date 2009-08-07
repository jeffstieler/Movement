	/*
	 
	AFCDeviceRef.m
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

// AFCDeviceRef is a fairly simple wrapper class for struct am_device, and allows
// the structure to be passed through delegates easily. It also includes a couple
// of helper methods for getting data out. 

#import "AFCDeviceRef.h"

@implementation AFCDeviceRef

-(id)initWithAFCDeviceStruct:(struct am_device *)dev {

	if (self = [super init]) {
		device = dev;
	}
	
	return self;	
}


-(NSString *)serialNumber {
	return [NSString stringWithCString:device->serial];
}

-(unsigned int)productID {
	return device->product_id;
}

-(unsigned int)deviceID {
	return device->device_id;
}

-(struct am_device *)device {
	return device;
}

@end
