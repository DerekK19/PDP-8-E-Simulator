/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	Utilities.c - Some general utilities and macros, esp. for Tiger compatibility
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
#import <mach/mach_time.h>

#include "Utilities.h"


@interface NSProcessInfo (OSVersion)		// available in NSProcessInfo.h since 10.10

typedef struct {
	long	majorVersion;
	long	minorVersion;
	long	patchVersion;
} NSOperatingSystemVersion;

- (NSOperatingSystemVersion) operatingSystemVersion;

@end


BOOL runningOnOSXVersion (long major, long minor, BOOL orBetter)
{
	if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10)
		return NO;	// up to 10.10, we use the NSAppKitVersionNumber compare macros
	NSOperatingSystemVersion vers = [[NSProcessInfo processInfo] operatingSystemVersion];
	return (vers.majorVersion == major && vers.minorVersion == minor) ||
		(orBetter && (vers.majorVersion > major || (vers.majorVersion == major && vers.minorVersion > minor)));
}


void adjustToolbarControlForTiger (NSView *view)
{
	if (runningOnTiger() &&
		[[[[(view) superview] superview] class]
			isSubclassOfClass:NSClassFromString(@"NSToolbarItemViewer")]) {
		NSPoint p = [(view) frame].origin;
		p.x += (float) 2.0;
		[(view) setFrameOrigin:p];
	}
}


void adjustTableHeaderForElCapitan (NSTableView *view)
// With El Capitan, the header of a table view is six pixel higher than with any OS X before.
// This El Capitan header adjustment causes scrolling anomalies in CPU memory view and in the
// memory inspector drawer, see [CPUMemoryViewControler updateVisibleMemoryRange] and
// [MemoryInspectorController visibleRange].
{
	if (runningOnElCapitanOrNewer()) {
		NSRect rect = [[view headerView] frame];
		rect.size.height -= 6;
		[[view headerView] setFrame:rect];
	}
}


static mach_timebase_info_data_t timebaseInfo;
	
	
uint64_t nanoseconds2absolute (uint64_t nanoseconds)	// see Technical Q&A QA1398
{
	if (timebaseInfo.denom == 0)
		mach_timebase_info (&timebaseInfo);
	return nanoseconds * timebaseInfo.denom / timebaseInfo.numer;
}


uint64_t absolute2nanoseconds (uint64_t absolute)	// see Technical Q&A QA1398
{
	if (timebaseInfo.denom == 0)
		mach_timebase_info (&timebaseInfo);
	return absolute * timebaseInfo.numer / timebaseInfo.denom;
}
