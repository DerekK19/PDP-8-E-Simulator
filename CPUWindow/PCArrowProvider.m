/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	PCArrowProvider.m - Provides the image for the PC arrow in the CPU memory view
 *
 *	This file is part of PDP-8/E Simulator.
 *
 *	PDP-8/E Simulator is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import <Cocoa/Cocoa.h>

#import "PCArrowProvider.h"
#import "Utilities.h"


#define PC_ARROW_3D_BLUE_IMAGE		@"pcArrowBlue.tiff"		// images from resource files
#define PC_ARROW_3D_GRAPHITE_IMAGE	@"pcArrowGraphite.tiff"
#define PC_ARROW_FLAT_BLACK_IMAGE	@"pcArrowBlack.tiff"

#define PC_ARROW_FLAT_GRAY_IMAGE	@"pcArrowGray"			// cached generated images
#define PC_ARROW_FLAT_COLORED_IMAGE	@"pcArrowColored"


@implementation PCArrowProvider


+ (PCArrowProvider *) sharedPCArrowProvider
{
	static PCArrowProvider *sharedPCArrowProvider;

	if (! sharedPCArrowProvider)
		sharedPCArrowProvider = [[self alloc] init];
	return sharedPCArrowProvider;
}


- (PCArrowProvider *) init
{
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifySystemColorsChanged:) name:NSSystemColorsDidChangeNotification object:nil];
	return self;
}


- (void) notifySystemColorsChanged:(NSNotification *)notification
// remove the colored flat PC arrow from the cache because the accent or highlight color might have changed
{
	// NSLog (@"PCArrow notifySystemColorsChanged");
	NSImage *image = [NSImage imageNamed:PC_ARROW_FLAT_COLORED_IMAGE];
	if (image)
		[image setName:nil];
}


- (NSImage *) generatePCArrowWithColor:(NSColor *)color
// this is time consuming and slows down PDP-8 trace mode a lot when executed for each image access,
// so the created images are cached by naming them
{
	NSImage *image = [NSImage imageNamed:PC_ARROW_FLAT_BLACK_IMAGE];
	[image lockFocus];
	[color set];
	NSSize size = [image size];
	NSRectFillUsingOperation (NSMakeRect(0, 0, size.width, size.height), NSCompositeSourceIn);
	[image unlockFocus];
	return image;
}


- (NSImage *) coloredPCArrow
{
	NSImage *image = [NSImage imageNamed:PC_ARROW_FLAT_COLORED_IMAGE];
	if (image == nil) {
		image = [self generatePCArrowWithColor:runningOnMojaveOrNewer() ?
			[NSColor controlAccentColor] : [NSColor selectedMenuItemColor]];
		[image setName:PC_ARROW_FLAT_COLORED_IMAGE];
	}
	return image;
}


- (NSImage *) grayPCArrow
{
	NSImage *image = [NSImage imageNamed:PC_ARROW_FLAT_GRAY_IMAGE];
	if (image == nil) {
		image = [self generatePCArrowWithColor:[NSColor grayColor]];
		[image setName:PC_ARROW_FLAT_GRAY_IMAGE];
	}
	return image;
}


- (NSImage *) imageForWindow:(NSWindow *)window
{
	NSImage *image = nil;
	if (runningOnYosemiteOrNewer()) {
		if ([window isMainWindow])
			image = [self coloredPCArrow];
		else
			image = [self grayPCArrow];
	} else {
		image = [NSImage imageNamed:([NSColor currentControlTint] == NSBlueControlTint && [window isKeyWindow])
				? PC_ARROW_3D_BLUE_IMAGE : PC_ARROW_3D_GRAPHITE_IMAGE];
	}
	return image;
}


@end
