/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	KeepInMenuWindow.m - Windows that are kept in the window menu when hidden
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

#import "KeepInMenuWindow.h"
#import "NSWindow+VisibilityDefaults.h"
#import "Utilities.h"


@implementation KeepInMenuWindow


#ifdef __MAC_10_10

- (id) initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style
	backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
// This init method avoids the High Sierra and Mojave console warning
// *** WARNING: Textured window <KeepInMenuWindow: 0x7fb060899bd0> is getting an implicitly transparent titlebar.
// This will break when linking against newer SDKs. Use NSWindow's -titlebarAppearsTransparent=YES instead.
{
	self = [super initWithContentRect:contentRect styleMask:(style & ~NSWindowStyleMaskTexturedBackground)
		backing:bufferingType defer:flag];
	if (style & NSWindowStyleMaskTexturedBackground) {
		[self setTitlebarAppearsTransparent:YES];
		[self setStyleMask:style];
	}
	// disable full screen and tabbing (automatically enabled with Sierra and newer)
	[self setCollectionBehavior:[self collectionBehavior] | NSWindowCollectionBehaviorFullScreenNone];
	if (runningOnSierraOrNewer())
		[NSWindow setAllowsAutomaticWindowTabbing:NO];
	return self;
}

#endif


- (BOOL) windowShouldClose:(NSWindow *)window
// When the delegate allows the window to close, close it and then re-add it to the window menu
{
	id delegate = [window delegate];
	if (delegate == nil || ! [delegate respondsToSelector:@selector(windowShouldClose:)] ||
		[delegate windowShouldClose:self]) {
		[window close];
		[self saveVisibilityInDefaults:NO];
		[NSApp addWindowsItem:window title:[window title] filename:NO];
	}
	return NO;
}


- (void) makeKeyAndOrderFront:(id)sender
{
	Boolean alreadyVisible = [self isVisible];
	[super makeKeyAndOrderFront:sender];
	if (! alreadyVisible)
		[self makeFirstResponder:[self initialFirstResponder]];
	[self saveVisibilityInDefaults:NO];
}


- (void) orderFrontFromDefaults:(id)sender
{
	if ([self getVisibilityFromDefaults])
		[self orderFront:sender];
	else
		[NSApp addWindowsItem:self title:[self title] filename:NO];
	[self makeFirstResponder:[self initialFirstResponder]];
	[self saveVisibilityInDefaults:NO];
}


- (void) orderBackFromDefaults:(id)sender
{
	if ([self getVisibilityFromDefaults])
		[self orderBack:sender];
	else
		[NSApp addWindowsItem:self title:[self title] filename:NO];
	[self makeFirstResponder:[self initialFirstResponder]];
	[self saveVisibilityInDefaults:NO];
}


@end
