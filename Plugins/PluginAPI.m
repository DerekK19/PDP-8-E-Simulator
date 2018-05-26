/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	PluginAPI.m - Plugin API Definitions for PDP-8/E I/O Device Plugins
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

#import "PluginAPI.h"
#import "Utilities.h"


@implementation PDP8Plugin


PDP8 *pdp8;		// plugin local pdp8 variable for the IOT functions


static void setPDP8 (PDP8 *p8)
{
	pdp8 = p8;	// set the plugin local pdp8 variable for the IOT function
}


- (void) setPDP8:(PDP8 *)p8
{
	pdp8 = p8;	// set the class variable pdp8
	setPDP8 (p8);
}


- (unsigned) apiVersion
{
	[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self
		file:[NSString stringWithCString:__FILE__] lineNumber:__LINE__
		description:NSLocalizedString(
			@"Your plugin must override the apiVersion method using the API_VERSION macro.",
			@"")];
	return CURRENT_PLUGIN_API_VERSION;
}


- (NSBundle *) bundle
{
	return bundle;
}


- (void) setBundle:(NSBundle *)bndl
{
	bundle = bndl;
}


- (NSString *) pluginName
{
	return [[bundle bundlePath] lastPathComponent];
}


- (void *) pluginPointer
{
	return (void *) self;
}


- (NSString *) ioInformationPlistName
{
	return DEFAULT_IO_INFO_FILENAME;
}


- (NSDictionary *) ioInformation
{
	return [NSDictionary dictionaryWithContentsOfFile:
		[bundle pathForResource:[self ioInformationPlistName] ofType:@"plist"]];
}


- (NSArray *) iotsForAddress:(int)ioAddress
{
	return nil;
}


- (NSArray *) skiptestsForAddress:(int)ioAddress
{
	return nil;
}


- (void) setIOFlag:(unsigned long)flag forIOFlagName:(NSString *)name;
{
}


- (void) loadNibs
{
	NSString *resourceName;
	
	NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSDirectoryEnumerator *resourcePathEnum =
		[[NSFileManager defaultManager] enumeratorAtPath:resourcePath];
	while (resourcePathEnum && (resourceName = [resourcePathEnum nextObject])) {
		if ([[resourceName pathExtension] isEqualToString:@"nib"])
			[NSBundle loadNibNamed:[resourceName lastPathComponent] owner:self];
	}
}


- (void) pluginDidLoad
{
}


- (void) CAF:(int)ioAddress
{
}


- (void) clearAllFlags:(int)ioAddress
{
}


- (void) resetDevice
{
}


@end
