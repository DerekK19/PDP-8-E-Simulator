/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	NSTableView+Scrolling.m - Category with additional scrolling methods
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
#import "NSTableView+Scrolling.h"


@implementation NSTableView (Scrolling)


- (void) scrollRowToTop:(NSInteger)row
{
	NSClipView *clipView = (NSClipView *) [self superview];
	if (clipView) {
		NSRect rowRect = [self rectOfRow:row];
		if (runningOnElCapitanOrNewer())
			rowRect.origin.y -= rowRect.size.height;
#if __LP64__
	// On initial load, the PC arrow in the CPU window is this amount of pixels too low with the 64-bit version,
	// a click on the PC table column moves it to the correct position, although all rect are identical.
	// Don't know why.
	//
	// With El Capitan and Sierra, there are still scrolling anomalies when you single step to the bottom
	// of the CPU window with cleared memory (AND 0 instructions), then hide the CPU window, then single step
	// one or two instructions, then show the CPU window and single step again. The PC location disappears
	// from the screen and jumps to the default location. Correctly, the PC location would stay at the last line
	// of the CPU windows, as can be observed with High Sierra. The 32-bit version works corrrectly with all
	// macOS versions.
		if (! [[self window] isVisible] && ! [[NSRunningApplication currentApplication] isFinishedLaunching]) {
			rowRect.origin.y += rowRect.size.height;
			if (runningOnElCapitan() || runningOnSierra())
				rowRect.origin.y += 6;
		}
#endif
		NSPoint newOrigin = [self convertPoint:rowRect.origin toView:clipView];
		[clipView scrollToPoint:newOrigin];
		NSScrollView *scrollView = (NSScrollView *) [clipView superview];
		if (scrollView)
			[scrollView reflectScrolledClipView:clipView];
	}
}



@end



