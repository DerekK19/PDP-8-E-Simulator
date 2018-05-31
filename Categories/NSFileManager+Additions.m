/*
 *    PDP-8/E Simulator
 *
 *    Copyright © 1994-2015 Bernhard Baehr
 *
 *    NSFileManager+Additions.h - Additional functions for file management
 *
 *    This file is part of PDP-8/E Simulator.
 *
 *    PDP-8/E Simulator is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import <Cocoa/Cocoa.h>

#import "utilities.h"
#import "NSFileManager+Additions.h"


#import <dlfcn.h>


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


- (BOOL) urlRef:(CFURLRef *)urlRef forPath:(NSString *)path
{
    BOOL ok = NO;
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, NO);
    if (url) {
        *urlRef = url;
        ok = YES;
    }
    return ok;
}

- (NSString *) pathResolved:(NSString *)path
{
    CFStringRef resolvedPath = nil;
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, NO);
    if (url != NULL) {
        CFErrorRef *err = nil;
        CFDataRef bookmark = CFURLCreateBookmarkDataFromFile(NULL, url, err);
        if (bookmark != NULL) {
            CFURLRef resolvedurl = CFURLCreateByResolvingBookmarkData(NULL, bookmark,
                                                                      kCFBookmarkResolutionWithoutUIMask, NULL, NULL, NO, err);
            if (resolvedurl != NULL) {
                resolvedPath = CFURLCopyFileSystemPath(resolvedurl, kCFURLPOSIXPathStyle);
                CFRelease (resolvedurl);
            }
            CFRelease(bookmark);
        }
        CFRelease (url);
    }
    NSString *rValue = (NSString *)CFBridgingRelease(resolvedPath);
    return rValue;
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
