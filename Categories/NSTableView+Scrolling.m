/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
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

#import "NSTableView+Scrolling.h"
#import "Utilities.h"


@implementation NSTableView (Scrolling)


- (void) scrollRowToTop:(NSInteger)row
{
	NSClipView *clipView = (NSClipView *) [self superview];
	if (clipView) {
		NSRect rowRect = [self rectOfRow:row];
		if (runningOnElCapitanOrNewer())
			rowRect.origin.y -= rowRect.size.height;
		NSPoint newOrigin = [self convertPoint:rowRect.origin toView:clipView];
		[clipView scrollToPoint:newOrigin];
		NSScrollView *scrollView = (NSScrollView *) [clipView superview];
		if (scrollView)
			[scrollView reflectScrolledClipView:clipView];
	}
}


@end



