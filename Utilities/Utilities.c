/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
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


#ifndef __MAC_10_10

@interface NSProcessInfo (OSVersion)		// available in NSProcessInfo.h since 10.10

typedef struct {
	long	majorVersion;
	long	minorVersion;
	long	patchVersion;
} NSOperatingSystemVersion;

- (NSOperatingSystemVersion) operatingSystemVersion;

@end

#endif


#ifndef __MAC_10_9

@interface NSProcessInfo (Activity)		// available in NSProcessInfo.h since 10.9

typedef enum  {
	NSActivityIdleDisplaySleepDisabled = (1ULL << 40),
	NSActivityIdleSystemSleepDisabled = (1ULL << 20),
	NSActivitySuddenTerminationDisabled = (1ULL << 14),
	NSActivityAutomaticTerminationDisabled = (1ULL << 15),
	NSActivityUserInitiated = (0x00FFFFFFULL | NSActivityIdleSystemSleepDisabled),
	NSActivityUserInitiatedAllowingIdleSystemSleep = (NSActivityUserInitiated & ~NSActivityIdleSystemSleepDisabled),
	NSActivityBackground = 0x000000FFULL,
	NSActivityLatencyCritical = 0xFF00000000ULL,
} NSActivityOptions;

- (id <NSObject>) beginActivityWithOptions:(NSActivityOptions)options reason:(NSString *)reason;
- (void) endActivity:(id <NSObject>)activity;

@end

#endif


BOOL runningOnOSXVersion (long major, long minor, BOOL orBetter)
{
	if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10)
		return NO;	// up to 10.10, we use the NSAppKitVersionNumber compare macros
	NSOperatingSystemVersion vers = [[NSProcessInfo processInfo] operatingSystemVersion];
	return (vers.majorVersion == major && vers.minorVersion == minor) ||
		(orBetter && (vers.majorVersion > major || (vers.majorVersion == major && vers.minorVersion > minor)));
}


@interface MojaveTableHeaderView: NSTableHeaderView
{
}
@end

@implementation MojaveTableHeaderView

- (void) drawRect:(NSRect)rect
{
	[super drawRect:rect];
	rect = NSInsetRect(rect, -1, 0);
	[[NSColor secondarySelectedControlColor] set];
	NSFrameRect (rect);
}

@end


void adjustTableHeaderForElCapitan (NSTableView *view)
// With El Capitan, the header of a table view is six pixel higher than with any OS X before.
// This El Capitan header adjustment causes scrolling anomalies in CPU memory view and in the
// memory inspector drawer, see [CPUMemoryViewControler updateVisibleMemoryRange] and
// [MemoryInspectorController visibleRange].
{
	if (runningOnElCapitanOrNewer()) {
		NSRect rect = [[view headerView] frame];
		rect.size.height -= 6;
		if (runningOnMojaveOrNewer()) {
			rect.size.height -= 2;
			// With Mojave Public Beta 18A389 from 12.09.2018, in Dark Mode, the frame of the
			// table header border is drawn in light gray when the height is decreased,
			// so we use a subclass that draws the frame in secondarySelectedControlColor.
			[view setHeaderView:[[[MojaveTableHeaderView alloc] initWithFrame:rect] autorelease]];
		} else
			[[view headerView] setFrame:rect];
	}
}


id disableAppNap (NSString *reason)
{
	id activity = nil;
	if (runningOnMavericksOrNewer())
		activity = [[NSProcessInfo processInfo] beginActivityWithOptions:
			NSActivityUserInitiated | NSActivityBackground | NSActivityLatencyCritical
			reason:reason];
	return activity;
}


void reenableAppNap (id activity)
{
	if (runningOnMavericksOrNewer())
		[[NSProcessInfo processInfo] endActivity:activity];
}


#ifndef __MAC_10_5

@implementation NSThread (MainThread)


+ (BOOL) isMainThread
{
	return pthread_main_np() != 0;
}


@end

#endif


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
