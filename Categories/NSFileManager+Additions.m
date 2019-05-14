/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	NSFileManager+Additions.m - Additional functions for file management
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

#import "utilities.h"
#import "NSFileManager+Additions.h"


#ifndef __MAC_10_6

/* declarations from Mac OS X 10.6 CFURL.h to dynamically load und call new APIs while building
   with the Mac OS X 10.4 SDK */

#import <dlfcn.h>

typedef struct __CFError *CFErrorRef;
typedef CFOptionFlags CFURLBookmarkResolutionOptions;

enum  {
	kCFBookmarkResolutionWithoutUIMask = ( 1UL << 8 ),
		// don't perform any UI during bookmark resolution
	kCFBookmarkResolutionWithoutMountingMask = ( 1UL << 9 ),
		// don't mount a volume during bookmark resolution
};

static CFDataRef (*CFURLCreateBookmarkDataFromFile) (CFAllocatorRef allocator,
	CFURLRef fileURL, CFErrorRef *errorRef);
static CFURLRef (*CFURLCreateByResolvingBookmarkData) (CFAllocatorRef allocator,
	CFDataRef bookmark, CFURLBookmarkResolutionOptions options, CFURLRef relativeToURL,
	CFArrayRef resourcePropertiesToInclude, Boolean* isStale, CFErrorRef* error);

#endif

	
/*
	NSFileManager: Resolve an alias
	Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSFileManager__Reso.m>
	(See copyright notice at <http://cocoa.karelia.com>)
	
	The old Alias Manager functions are depecated since Mac OS 10.8 and no longer work with OS X 10.10.
	The CFURL Bookmark functions are available since Mac OS 10.6. Because we build against the
	Mac OS X 10.4 SDK, we call them dynamically. For the new code, see
	http://stackoverflow.com/questions/21244781
*/


@implementation NSFileManager (Additions)


- (BOOL) fsRef:(FSRef *)fsRef forPath:(NSString *)path
{
	BOOL ok = NO;
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, NO);
	if (url) {
		ok = CFURLGetFSRef(url, fsRef);
		CFRelease (url);
	}
	return ok;
}


- (NSString *) pathResolvedNew:(NSString *)path
// This code runs with Mac OS 10.6 and better; the dlsym() is only required until we build with newer SDKs
{
#ifndef __MAC_10_6
	if (CFURLCreateBookmarkDataFromFile == NULL)
		CFURLCreateBookmarkDataFromFile = dlsym(RTLD_NEXT, "CFURLCreateBookmarkDataFromFile");
	if (CFURLCreateByResolvingBookmarkData == NULL)
		CFURLCreateByResolvingBookmarkData = dlsym(RTLD_NEXT, "CFURLCreateByResolvingBookmarkData");
#endif
	CFStringRef resolvedPath = nil;
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, NO);
	if (url != NULL) {
		CFErrorRef *err = nil;
		CFDataRef bookmark = CFURLCreateBookmarkDataFromFile(NULL, url, err);
		if (bookmark != NULL) {
			CFURLRef resolvedurl = CFURLCreateByResolvingBookmarkData(NULL, bookmark,
				kCFBookmarkResolutionWithoutUIMask, NULL, NULL, NULL, err);
			if (resolvedurl != NULL) {
				resolvedPath = CFURLCopyFileSystemPath(resolvedurl, kCFURLPOSIXPathStyle);
				CFRelease (resolvedurl);
			}
			CFRelease (bookmark);
		}
		CFRelease (url);
	}
	return [((NSString *) resolvedPath) autorelease];
}


- (NSString *) pathResolvedOld:(NSString *)path
// This code runs with Mac OS 10.4 to 10.9, it is deprecated since Mac OS 10.8, it doesn't work with Yosemite
{
	CFStringRef resolvedPath = nil;
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, NO);
	if (url != NULL) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile(&fsRef, true, &targetIsFolder, &wasAliased) == noErr &&
				wasAliased) {
				CFURLRef resolvedurl = CFURLCreateFromFSRef(NULL, &fsRef);
				if (resolvedurl != NULL) {
					resolvedPath = CFURLCopyFileSystemPath(resolvedurl,
						kCFURLPOSIXPathStyle);
					CFRelease (resolvedurl);
				}
			}
		}
		CFRelease (url);
	}
	return [((NSString *) resolvedPath) autorelease];
}


- (NSString *) pathResolved:(NSString *)path
{
	return runningOnSnowLeopardOrNewer() ? [self pathResolvedNew:path] : [self pathResolvedOld:path];
}


- (BOOL) isAliasPath:(NSString *)path
{
	return [self pathResolved:path] != nil;
}


- (NSString *) resolveAliasPath:(NSString *)path
{
	NSString *resolved = [self pathResolved:path];
	return resolved ? resolved : path;
}


@end
