//
//  JSScrollView.m
//  iPhone App Organizer
//
//  Created by Jeff Stieler on 8/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JSScrollView.h"


@implementation JSScrollView

- (void)reflectScrolledClipView:(NSClipView *)aClipView {
	
	id appController = [[self window] delegate];
	for (id controller in [appController screenControllers]) {
		[[controller screen] reloadData];
	}
	
	[super reflectScrolledClipView:aClipView];
}

@end
