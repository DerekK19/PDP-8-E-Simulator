/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	TableCornerView.m - Status indicator and button corner view for a NSTableControl
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
#import "TableCornerView.h"


@interface TableCornerCell : NSTableHeaderCell
{
}
@end


@implementation TableCornerCell


- (void) setState:(int)state
{
	// ignore state setting caused by mouse klick, otherwise the cell switchs from white to gray
	// send the action here because NSTableHeaderControl does not send any action
	[NSApp sendAction:[self action] to:[self target] from:self];
}


/* With Yosemie 10.10 14A389 and 10.10.1 14B25, there are some optical glitches with the TableCornerCell when it is
   used with an image (initImageCell: and setImageNamed: methods) (Yosemite NSTableHeaderCell bugs?):
   - the background is drawn in very light gray, not completely white (white only when the window is deactivated)
   - the cell is not highlighted when clicked
   - the left separator is not down, but the right one in the border of the scroll view (the borders appear
     when you set scroll bars to always be visible in the General system preferences
   Reported to Apple with bug ID 18848420, closed with the statement "this is the new look".
   So we implement the correct Yosemite behaviour in the highlight:withFrame:inView and drawWithFram:inView: methods
   These glitches are still present with 10.10.4, with a little different behaviour. (Even with Mavericks, there are
   minor glitches: the right separator is drawn in the border of the scroll view.) The following implementation is
   not absolute perfect, but the remaining glitches are not striking.
*/


- (NSRect) framerect:(NSRect)frame
{
	NSRect rect;
	rect.size = [[self image] size];
	unsigned width = frame.size.width;
	if (width % 2 == 0)
		width--;
	rect.origin.x = (width - rect.size.width) / 2;
	if (rect.origin.x >= 2)
		rect.origin.x++;
	rect.origin.y = (frame.size.height - rect.size.height) / 2;
	return rect;
}


- (void) highlight:(BOOL)flag withFrame:(NSRect)frame inView:(NSView *)view
{
	// [super hightlight:NO ...] does not cause an unhighlight of the cell - Cocoa bug?
	if (flag) {
		if (runningOnYosemiteOrNewer()) {	// else, there is no highlight of the wrongly gray background
			// draw frame at the left (this is clipped when the column separator is visible)
			[[NSColor secondarySelectedControlColor] set];
			NSRect rect = [self framerect:frame];
			rect.origin.x--;
			rect.size.width++;
			[NSBezierPath fillRect:rect];
			// draw content of the table corner view
			[[NSColor controlHighlightColor] set];
			[NSBezierPath fillRect:[self framerect:frame]];
			[self drawWithFrame:frame inView:view];
		} else
			[super highlight:YES withFrame:frame inView:view];
	} else {
		[self drawWithFrame:frame inView:view];
		if (runningOnYosemiteOrNewer())		// when moving the cursor out of the frame with mouse key down
			[view setNeedsDisplay:YES];
	}
}


- (void) drawWithFrame:(NSRect)frame inView:(NSView *)view
{
	if (runningOnYosemiteOrNewer()) {
		// else the background is drawn in light gray and a separator is drawn at the right, not in the frame
		[[NSColor secondarySelectedControlColor] set];
		[NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 1)]; // bottom line
		NSImage *image = [self image];
		if (image)
			[image drawInRect:[self framerect:frame] fromRect:NSZeroRect
				operation:NSCompositeSourceOver fraction:1];
	} else
		[super drawWithFrame:frame inView:view];
}


@end


@implementation TableCornerView


- (TableCornerView *) initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
        [self setCell:[[TableCornerCell alloc] init]];
		[self setClickable:NO];
	}
	return self;
}


- (void) setImageNamed:(NSString *)name toolTip:(NSString *)toolTip
{
	[[self cell] setImage:[NSImage imageNamed:name]];
	[self setToolTip:toolTip];
}


- (void) mouseDown:(NSEvent *)event
{
	if (clickable)
		[super mouseDown:event];
}


- (BOOL) isFlipped
// don't know why this is required - see http://zzot.net/2004/11/20/nstableheadercell/
{
	return ! runningOnYosemiteOrNewer();	// see above for Yosemite drawing glitches 

}


- (BOOL) isClickable
{
	return clickable;
}


- (void) setClickable:(BOOL)flag
{
	clickable = flag;
}


@end
