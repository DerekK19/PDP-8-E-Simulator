/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	HelpMenuManager.m - Manager for Help menu items of plug-ins
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

#import "Utilities.h"
#import "HelpMenuManager.h"
#import "NSFileManager+Additions.h"


@implementation HelpMenuManager


+ (HelpMenuManager *) sharedHelpMenuManager
{
	static HelpMenuManager *sharedHelpMenuManager;

	if (! sharedHelpMenuManager)
		sharedHelpMenuManager = [[self alloc] init];
	return sharedHelpMenuManager;
}


- (HelpMenuManager *) init
{
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationWillTerminate:)
		name:NSApplicationWillTerminateNotification object:nil];
	registeredHelpBookDomains = [[NSMutableArray alloc] initWithCapacity:10];
	return self;
}


- (void) unregisterHelpBookForDomain:(NSString *)domain
// see http://lists.apple.com/archives/carbon-development/2003/Nov/msg00090.html
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:
		[defaults persistentDomainForName:@"com.apple.help"]];
	[dict removeObjectForKey:domain];
	[defaults setPersistentDomain:dict forName:@"com.apple.help"];
}


- (void) notifyApplicationWillTerminate:(NSNotification *)notification
{
	NSString *domain;
	
	NSEnumerator *enumerator = [registeredHelpBookDomains objectEnumerator];
	while ((domain = [enumerator nextObject]))
		[self unregisterHelpBookForDomain:domain];
}


- (NSURL *) helpURLForHelpMenuItem:(id)sender
// extract the URL of the help page from ~/Library/Preferences/com.apple.help.plist
{
	NSArray *array;
	NSString *id;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults persistentDomainForName:@"com.apple.help"];
	
	if (runningOnSnowLeopardOrNewer()) {
		// up to Mountain Lion, the ID is the title of the help book
		// starting with Mavericks, the ID is the bundle identifier of the plug-in containing the help book
		id = runningOnMavericksOrNewer() ? [sender representedObject] : [sender title];
		dict = [dict valueForKey:@"RegisteredBooks"];
		NSEnumerator *enumerator = [dict objectEnumerator];
		while ((array = [enumerator nextObject])) {
			dict = [array objectAtIndex:0];
			if ([id isEqualToString:[dict objectForKey:@"id"]]) {
				NSString *url = [dict objectForKey:@"url"];
				return [url hasPrefix:@"file://"] ?	// all macOS versions before Mojave
					[NSURL URLWithString:[url stringByAppendingString:@"index.html"]]
					:				// starting with Mojave, it is an absolute path
					[NSURL fileURLWithPath:[url stringByAppendingString:@"/index.html"]];
			}
		}
	} else {
		// for Tiger and Leopard, the ID is the bundle identifier of the plug-in containing the help book
		id = [sender representedObject];
		array = [dict objectForKey:id];
		if (array) {
			array = [array objectAtIndex:0];
			NSString *url = [array objectAtIndex:1];
			return [NSURL URLWithString:[url stringByAppendingString:@"index.html"]];
		}
	}
	return nil;
}


- (void) showHelp:(id)sender
{
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
		[[NSWorkspace sharedWorkspace] openURL:[self helpURLForHelpMenuItem:sender]];
	else {
#ifdef __MAC_10_10
		NSString *id = [sender representedObject];
		[[NSHelpManager sharedHelpManager] openHelpAnchor:id inBook:id];
#else
		AHLookupAnchor ((CFStringRef) [sender title], (CFStringRef) [sender representedObject]);
#endif
	}
}


- (void) addHelpMenuItem:(NSString *)title id:(NSString *)id
{
	NSMenu *helpMenu = [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Help", @"")] submenu];
	NSInteger n = [helpMenu numberOfItems];
	int i;
	for (i = 1; i < n; i++) {
		switch ([[[helpMenu itemAtIndex:i] title] compare:title]) {
		case NSOrderedSame :
			n = -1;
			break;
		case NSOrderedDescending :
			n = i;
			break;
		default :
			break;
		}
	}
	if (n > 0) {
		NSMenuItem *item = [helpMenu insertItemWithTitle:title action:@selector(showHelp:)
			keyEquivalent:@"" atIndex:n];
		[item setTarget:self];
		[item setRepresentedObject:id];
	}
}


- (void) addBundleHelp:(NSBundle *)bundle
{
	FSRef fsRef;
	
	if ([[NSFileManager defaultManager] fsRef:&fsRef forPath:[bundle bundlePath]]) {
		[self unregisterHelpBookForDomain:[bundle bundleIdentifier]];
#ifdef __MAC_10_6
		if ([[NSHelpManager sharedHelpManager] registerBooksInBundle:bundle]) {
#else
		if (AHRegisterHelpBook(&fsRef) == noErr) {
#endif
			[registeredHelpBookDomains addObject:[bundle bundleIdentifier]];
			NSString *bookTitle = [[bundle infoDictionary] objectForKey:@"CFBundleHelpBookName"];
			if (bookTitle)
				[self addHelpMenuItem:bookTitle id:[bundle bundleIdentifier]];
		}
	}
}


@end
