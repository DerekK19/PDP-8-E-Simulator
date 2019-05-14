/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	Utilities.h - Some general utilities and macros, esp. for Tiger compatibility
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


// Macro to print a log message when the code is compiled with asserts
#if defined(NS_BLOCK_ASSERTIONS)
#define LOG_ASSERTING()
#else
#define LOG_ASSERTING()		NSLog (@"%@ - Compiled with assertions.", [self class])
#endif


// Constants from NSApplication.h that are not in the 10.4 SDK
#define NSAppKitVersionNumber10_4	824
#define NSAppKitVersionNumber10_5	949
#define NSAppKitVersionNumber10_6	1038
#define NSAppKitVersionNumber10_7	1138
#define NSAppKitVersionNumber10_8	1187
#define NSAppKitVersionNumber10_9	1265
#define NSAppKitVersionNumber10_10	1343	// note 10.10.4 has NSAppKitVersionNumber == 1348.17

// for Yosemite and better, we don't rely on NSAppKitVersionNumber, but use [NSProcessInfo operatingSystemVersion]
BOOL runningOnOSXVersion (long major, long minor, BOOL orBetter);

#define runningOnTiger()		(floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_4)
#define runningOnTigerOrNewer()		(NSAppKitVersionNumber >= NSAppKitVersionNumber10_4)
#define runningOnLeopard()		(floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_5)
#define runningOnLeopardOrNewer()	(NSAppKitVersionNumber >= NSAppKitVersionNumber10_5)
#define runningOnSnowLeopard()		(floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_6)
#define runningOnSnowLeopardOrNewer()	(NSAppKitVersionNumber >= NSAppKitVersionNumber10_6)
#define runningOnLion()			(floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_7)
#define runningOnLionOrNewer()		(NSAppKitVersionNumber >= NSAppKitVersionNumber10_7)
#define runningOnMountainLion()		(floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_8)
#define runningOnMountainLionOrNewer()	(NSAppKitVersionNumber >= NSAppKitVersionNumber10_8)
#define runningOnMavericks()		(floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_9)
#define runningOnMavericksOrNewer()	(NSAppKitVersionNumber >= NSAppKitVersionNumber10_9)
#define runningOnYosemite()		runningOnOSXVersion(10, 10, NO)
#define runningOnYosemiteOrNewer()	runningOnOSXVersion(10, 10, YES)
#define runningOnElCapitan()		runningOnOSXVersion(10, 11, NO)
#define runningOnElCapitanOrNewer()	runningOnOSXVersion(10, 11, YES)
#define runningOnSierra()		runningOnOSXVersion(10, 12, NO)
#define runningOnSierraOrNewer()	runningOnOSXVersion(10, 12, YES)
#define runningOnHighSierra()		runningOnOSXVersion(10, 13, NO)
#define runningOnHighSierraOrNewer()	runningOnOSXVersion(10, 13, YES)
#define runningOnMojave()		runningOnOSXVersion(10, 14, NO)
#define runningOnMojaveOrNewer()	runningOnOSXVersion(10, 14, YES)


void adjustTableHeaderForElCapitan (NSTableView *view);


id disableAppNap (NSString *reason);		// needs NSProcessInfo from the 10.9 SDK
void reenableAppNap (id activity);


#if __LP64__
// With Mojave public beta, [[NSAppearance currentAppearance] name] still returns NSAppearanceNameAquaDark when the
// AppleInterfaceThemeChangedNotification is posted after a switch back to the light appearance, so we can't use
// this to detect the current appearance mode.
#define isMojaveDarkModeActive()	(runningOnMojaveOrNewer() && [@"Dark" isEqualToString:	\
						[[NSUserDefaults standardUserDefaults]		\
							stringForKey:@"AppleInterfaceStyle"]])
#else
#define isMojaveDarkModeActive()	NO
#endif

#define THEME_CHANGED_NOTIFICATION	@"AppleInterfaceThemeChangedNotification"


#ifndef __MAC_10_5

@interface NSThread (MainThread)

+ (BOOL) isMainThread;

@end

#endif


#define NSAssertRunningOnMainThread()	NSAssert ([NSThread isMainThread], @"Called from non-main thread")


#ifndef __MAC_10_5
// NSCondition is available since 10.0 but missing in the headers until 10.5, see NSLock.h

@interface NSCondition : NSObject <NSLocking>
{
@private
	void *_priv;
}

- (void) wait;
- (BOOL) waitUntilDate:(NSDate *)limit;
- (void) signal;
- (void) broadcast;

@end

#endif


#ifndef __MAC_10_5
// NSInteger and NSUInteger are available since 10.5
// when not defined, we compile with Xcode 3 for 32-Bit PPC oder x86, so they are int, not long

typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;

#endif


#ifndef __MAC_10_14
// Accent colors were added with Mojave

@interface NSColor (Mojave)

+ (NSColor *) controlAccentColor;

@end

#endif


// [[NSUserDefaults standardUserDefaults] stringForKey:LAST_FILE_PANEL_DIR_KEY]
// returns the default start directory for file dialogs
#define LAST_FILE_PANEL_DIR_KEY		@"LastPanelDir"


// Minimum and maximum macro
#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) < (b) ? (b) : (a))


// see Technical Q&A QA1398
uint64_t nanoseconds2absolute (uint64_t nanoseconds);
uint64_t absolute2nanoseconds (uint64_t absolute);

