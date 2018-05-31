/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	PluginManager.m - Manager for I/O Device Plugins
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

#import "PluginManager.h"
#import "PluginAPI.h"
#import "PDP8.h"
#import "SkipController.h"
#import "IOFlagController.h"
#import "Assembler.h"
#import "Disassembler.h"
#import "OctalFormatter.h"
#import "HelpMenuManager.h"
#import "Unicode.h"
#import "NSFileManager+Additions.h"


#define PLUGIN_EXTENSION		@"pdp8Plugin"
#define PLUGIN_APPSUPPORT_PATH		@"Application Support/PDP-8:E Simulator"
#define PLUGIN_NEXTTOAPP_PATH		@"../PDP-8:E Simulator Plugins"


@implementation PluginManager


- (BOOL) canInstallIOTs:(NSArray *)mnemonics withIOAddresses:(NSArray *)ioAddresses
	noLoadMessage:(NSString *)noLoadMessage
{
	NSString *ioAddress;

	if (! mnemonics || ! [mnemonics isKindOfClass:[NSArray class]]) {
		[self noLoadAlertWithMessage:NSLocalizedString(@"Invalid IOT information in the I/O description of the plug-in", @"")
				      okText: noLoadMessage];
		return NO;
	}
	if (! ioAddresses || ! [ioAddresses isKindOfClass:[NSArray class]]) {
		[self noLoadAlertWithMessage:NSLocalizedString(@"Invalid I/O address information in the I/O description of the plug-in.", @"")
				      okText: noLoadMessage];
		return NO;
	}
	if ([mnemonics count] != 8 * [ioAddresses count]) {
		[self noLoadAlertWithMessage:NSLocalizedString(@"The number of IOTs does not match number of I/O addresses in the I/O description of the plug-in.", @"")
				      okText: noLoadMessage];
		return NO;
	}
	NSEnumerator *enumerator = [ioAddresses objectEnumerator];
	while ((ioAddress = [enumerator nextObject])) {
		NSNumber *number;
		if (! [[OctalFormatter formatterWithBitMask:077 wildcardAllowed:NO] getObjectValue:&number
			forString:ioAddress errorDescription:nil]) {
			[self noLoadAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Invalid I/O address %C%@%C in the I/O description of the plug-in.", @""), UNICODE_LEFT_DOUBLEQUOTE, ioAddress, UNICODE_RIGHT_DOUBLEQUOTE]
					      okText: noLoadMessage];
			return NO;
		}
		int addr = [number intValue];
		if (! [pdp8 isIOAddressAvailable:addr]) {
			[self noLoadAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The I/O address %2.2o requested by the plug-in is already in use.", @""), addr]
					      okText: noLoadMessage];
			return NO;
		}
	}
	return YES;
}

- (void) noLoadAlertWithMessage:(NSString *)message okText:(NSString *)okText
{
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = okText;
	alert.informativeText = message;
	[alert runModal];
}

- (void) installIOTs:(NSArray *)mnemonics withAddresses:(NSArray *)ioAddresses forPlugin:(PDP8Plugin *)plugin
{
	int i;
	NSString *ioAddress;

	int base = 0;
	NSEnumerator *ioAddrEnum = [ioAddresses objectEnumerator];
	while ((ioAddress = [ioAddrEnum nextObject])) {
		NSNumber *number;
		[[OctalFormatter formatterWithBitMask:077 wildcardAllowed:NO] getObjectValue:&number
			forString:ioAddress errorDescription:nil];
		int addr = [number intValue];
		[pdp8 setPluginPointer:(__bridge void *)(plugin) forIOAddress:addr];
		NSArray *iots = [plugin iotsForAddress:addr];
		if (iots) {
			NSArray *skiptests = [plugin skiptestsForAddress:addr];
			int opcode = 06000 | (addr << 3);
			for (i = 0; i < 8; i++) {
				NSValue *iot = [iots objectAtIndex:i];
				[pdp8 setIOT:iot forOpcode:opcode | i];
				NSValue *skiptest = skiptests ? [skiptests objectAtIndex:i] : nil;
				[skipController addSkiptest:skiptest forInstruction:iot];
				NSString *mnemonic = [mnemonics objectAtIndex:base + i];
				[[Assembler sharedAssembler] addMnemonic:mnemonic forIOT:opcode | i];
				[[Disassembler sharedDisassembler] addMnemonic:mnemonic forIOT:opcode | i];
			}
		}
		base += 8;
	}
}


- (BOOL) canInstallIOFlags:(NSArray *)ioFlags noLoadMessage:(NSString *)noLoadMessage
{
	if (! ioFlags || ! [ioFlags isKindOfClass:[NSArray class]]) {
		[self noLoadAlertWithMessage:NSLocalizedString(@"Invalid I/O flag information in the I/O description of the plug-in.", @"")
				      okText:noLoadMessage];
		return NO;
	}
	if ([ioFlags count] > [ioFlagController numberOfAvailableFlags]) {
		[self noLoadAlertWithMessage:NSLocalizedString(@"There are not enough I/O flags available.", @"")
				      okText:noLoadMessage];
		return NO;
	}
	return YES;
}


- (void) installIOFlags:(NSArray *)ioFlags forPlugin:(PDP8Plugin *)plugin
{
	NSString *ioFlagName;
	
	NSEnumerator *enumerator = [ioFlags objectEnumerator];
	while ((ioFlagName = [enumerator nextObject]))
		[plugin setIOFlag:[ioFlagController addIODevice:ioFlagName] forIOFlagName:ioFlagName];
}


- (void) resetAllDevices
{
	PDP8Plugin *plugin;
	
	NSEnumerator *enumerator = [pluginInstances objectEnumerator];
	while ((plugin = [enumerator nextObject]))
		[plugin resetDevice];
}


- (NSString *) noLoadMessage:(NSString *)pluginName
{
	return [NSString stringWithFormat:NSLocalizedString(@"The plug-in %C%@%C will not be loaded.", @""),
		UNICODE_LEFT_DOUBLEQUOTE, pluginName, UNICODE_RIGHT_DOUBLEQUOTE];
}


- (PDP8Plugin *) loadPlugin:(NSBundle *)bundle
{
	PDP8Plugin *plugin = nil;
	Class principalClass = [bundle principalClass];
	if (principalClass && [principalClass isSubclassOfClass:[PDP8Plugin class]]) {
		plugin = [[principalClass alloc] init];
		if (plugin) {
			[plugin apiVersion];	// plugin must overrides this method, otherwise we crash
			[plugin setBundle:bundle];
			[plugin setPDP8:pdp8];
			NSDictionary *ioInfo = [plugin ioInformation];
			NSArray *ioFlagNames = [ioInfo objectForKey:IO_INFO_IOFLAGS_KEY];
			NSArray *ioAddresses = [ioInfo objectForKey:IO_INFO_IOADDRESSES_KEY];
			NSArray *mnemonics = [ioInfo objectForKey:IO_INFO_IOTS_KEY];
			if ([self canInstallIOFlags:ioFlagNames
				noLoadMessage:[self noLoadMessage:[plugin pluginName]]] &&
				[self canInstallIOTs:mnemonics withIOAddresses:ioAddresses
					noLoadMessage:[self noLoadMessage:[plugin pluginName]]]) {
				[self installIOFlags:[ioInfo objectForKey:IO_INFO_IOFLAGS_KEY]
					forPlugin:plugin];
				[self installIOTs:mnemonics withAddresses:ioAddresses forPlugin:plugin];
				[plugin loadNibs];
				[plugin pluginDidLoad];
				[[HelpMenuManager sharedHelpMenuManager] addBundleHelp:bundle];
			} else {
				// unload is a 10.5 method (does nothing on 10.4), but we use the 10.4 SDK
				// so use performSelector: to avoid unknown message warning
				[bundle performSelector:@selector(unload)];
				return nil;
			}
		} else {
			[self noLoadAlertWithMessage:NSLocalizedString(@"Cannot instantiate the plug-in.", @"")
					      okText:[self noLoadMessage:[[bundle bundlePath] lastPathComponent]]];
		}
	} else {
		[self noLoadAlertWithMessage:principalClass ?
		 NSLocalizedString(@"The plug-in has an invalid principal class.", @"") :
		 NSLocalizedString(@"Cannot determine the principal class of the plug-in.", @"")
				      okText:[self noLoadMessage:[[bundle bundlePath] lastPathComponent]]];
	}
	return plugin;
}


- (NSArray *) loadAllPlugins
{
	NSEnumerator	*searchPathEnum;
	NSString	*path;
	NSString	*bundleName;
	
	NSMutableArray	*bundleSearchPaths = [NSMutableArray array];
	NSMutableArray	*plugins = [NSMutableArray array];
 
	searchPathEnum = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
		NSAllDomainsMask - NSSystemDomainMask, YES) objectEnumerator];
	while ((path = [searchPathEnum nextObject]))
		[bundleSearchPaths addObject:[path stringByAppendingPathComponent:PLUGIN_APPSUPPORT_PATH]];
	[bundleSearchPaths addObject:[[[NSBundle mainBundle] bundlePath]
		stringByAppendingPathComponent:PLUGIN_NEXTTOAPP_PATH]];
	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
 	searchPathEnum = [bundleSearchPaths objectEnumerator];
	while ((path = [searchPathEnum nextObject])) {
		NSDirectoryEnumerator *bundlePathEnum =
			[[NSFileManager defaultManager] enumeratorAtPath:path];
		while (bundlePathEnum && (bundleName = [bundlePathEnum nextObject])) {
			[bundlePathEnum skipDescendents];
			if ([[bundleName pathExtension] isEqualToString:PLUGIN_EXTENSION]) {
				NSBundle *bundle = [NSBundle bundleWithPath:
					[[NSFileManager defaultManager] resolveAliasPath:
						[path stringByAppendingPathComponent:bundleName]]];
				if (bundle) {
					PDP8Plugin *plugin = [self loadPlugin:bundle];
					if (plugin)
						[plugins addObject:plugin];
				} else
					[self noLoadAlertWithMessage:NSLocalizedString(@"Loading of the plug-in bundle failed.", @"")
							      okText:[self noLoadMessage:bundleName]];
			}
		}
	}
	return plugins;
}


- (void) notifyApplicationWillFinishLaunching:(NSNotification *)notification
{
	pluginInstances = [self loadAllPlugins];
}


- (void) notifyApplicationDidFinishLaunching:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PLUGINS_LOADED_NOTIFICATION object:nil];
}


- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationWillFinishLaunching:)
		name:NSApplicationWillFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationDidFinishLaunching:)
		name:NSApplicationDidFinishLaunchingNotification object:nil];
}


@end
