/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	NSWindow+VisibilityDefaults.m - Category for saving windows visiblity in the defaults
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

#import "NSWindow+VisibilityDefaults.h"
#import "Unicode.h"


#define WINDOW_VISIBILITY_DEFAULTS_KEY_SUFFIX	@" Visible"	// with leading space


@implementation NSWindow (VisibilityDefaults)


- (void) saveVisibilityInDefaults:(BOOL) saveInvertedValue
{
	NSString *frameAutosaveName = [self frameAutosaveName];
	if (frameAutosaveName)
		[[NSUserDefaults standardUserDefaults] setBool:saveInvertedValue ^ [self isVisible] forKey:
			[frameAutosaveName stringByAppendingString:WINDOW_VISIBILITY_DEFAULTS_KEY_SUFFIX]];
}


- (BOOL) getVisibilityFromDefaults
{
	NSNumber *visible = nil;
	NSString *frameAutosaveName = [self frameAutosaveName];
	if (frameAutosaveName) {
		visible = [[NSUserDefaults standardUserDefaults] objectForKey:
			[frameAutosaveName stringByAppendingString:WINDOW_VISIBILITY_DEFAULTS_KEY_SUFFIX]];
	} else
		NSLog (@"Missing autosave name for window %C%@%C",
			UNICODE_LEFT_DOUBLEQUOTE, [self title], UNICODE_RIGHT_DOUBLEQUOTE);
	// check existance of the key in the preferences to make all windows visible at the very first launch
	// of the simulator, but not the panels
	return (frameAutosaveName == nil || visible == nil) ?
		! [self isKindOfClass:[NSPanel class]] : [visible boolValue];
}


@end
