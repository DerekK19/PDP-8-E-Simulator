/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	MemoryInspectorController.m - Controller for the Memory Inspectors Drawer
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
#import <objc/objc-runtime.h>

#import "MemoryInspectorController.h"
#import "MemoryInspectorProtocol.h"
#import "NonWrappingTableView.h"
#import "NSTableView+Scrolling.h"
#import "TableCornerView.h"
#import "OctalFormatter.h"
#import "Utilities.h"
#import "PDP8.h"


#define ADDR_COLUMN		0
#define OCTAL_COLUMN		1
#define CONTENT_COLUMN		2

#define ADDR_COLUMN_ID		@"0"
#define OCTAL_COLUMN_ID		@"1"
#define CONTENT_COLUMN_ID	@"2"

#define CURRENT_INSPECTOR_CLASS_PREFS_KEY	@"MemInspectorClass"
#define TOP_ROW_PREFS_KEY			@"MemInspectorTopRow"
#define ALIGNMENT_PREFS_KEY			@"MemInspectorAlign"
#define INSPECTOR_OPEN_PREFS_KEY		@"MemInspectorOpen"


@implementation NSFormatter (OrderInMemoryInspectorMenu)


- (NSComparisonResult) compareOrderInMemoryInspectorMenu:(id <MemoryInspector>)inspector
{
	return [[(id <MemoryInspector>) self orderInMemoryInspectorMenu]
		compare:[inspector orderInMemoryInspectorMenu]];
}


@end


@implementation MemoryInspectorScrollView : NSScrollView


- (void) setFrame:(NSRect)frameRect
/* Auto resizing of the drawer makes the memory table view overlap the memory format popup
   menu when the CPU window shrinks to the title bar (while "go" mode). (Cocoa bug?)
   This methods calculates the scroll view height from the drawer height and the initial,
   correct height delta between drawer and scroll view height. */
{
	static float delta = (float) 0.0;
	
	if (delta == 0.0) {
		if ([self window])
			delta = [[self window] frame].size.height - frameRect.size.height;
	} else
		frameRect.size.height = [[self window] frame].size.height - delta;
	[super setFrame:frameRect];
}


@end


@implementation MemoryInspectorController


- (void) cancelEditingInInspector
{
	NSResponder *first, *next;
	
	for (first = next = [[NSApp keyWindow] firstResponder]; next; next = [next nextResponder]) {
		if (next == [memoryInspectorDrawer contentView] &&
			[[first class] isSubclassOfClass:[NSTextView class]]) {
			[first doCommandBySelector:@selector(cancelOperation:)];
			break;
		}
	}
}


- (NSArray *) allMemoryInspectors
{
    NSMutableArray *inspectors = [NSMutableArray array];
#if !__OBJC2__
	int i;
	
	int numClasses = 0;
	int newNumClasses = objc_getClassList(NULL, 0);
	
	Class *allClasses = NULL;
	while (numClasses < newNumClasses) {
		numClasses = newNumClasses;
		allClasses = realloc(allClasses, sizeof(Class) * numClasses);
		newNumClasses = objc_getClassList(allClasses, numClasses);
	}
	for (i = 0; i < numClasses; i++) {
		Class currentClass = allClasses[i];
		while (currentClass) {
            if ([currentClass superclass] == [NSFormatter class] &&
				[currentClass conformsToProtocol:@protocol(MemoryInspector)]) {
				[inspectors addObject:[[[allClasses[i] alloc] init] autorelease]];
				break;
			}
			currentClass = [currentClass superclass];
		}
        }
	}
	free (allClasses);
#else
{
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspector6BitASCII") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspector8BitASCII") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorOS8Packed8BitASCII") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorSignedInteger") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorUnsignedInteger") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorDWSignedInteger") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorDWUnsignedInteger") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorFPP8AFPFloatingPoint") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorFPP8AEPFloatingPoint") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorFortranIIFloatingPoint") alloc] init] autorelease]];
    [inspectors addObject:[[[NSClassFromString(@"MemoryInspectorPascalSFloatingPoint") alloc] init] autorelease]];
}
#endif
	[inspectors sortUsingSelector:@selector(compareOrderInMemoryInspectorMenu:)];
	return inspectors;
}


- (NSRange) visibleRange
{
	// see also [CPUMemoryViewController updateVisibleMemoryRange] and [NSTableView(Scrolling) scrollRowToTop:]
	NSRange range;
	range.location = range.length = 0;
	NSRect rect = [memoryView visibleRect];
	if (rect.size.height > 0) {	// zero immediately after "Stop" when the window is not yet enlarged
		if (runningOnElCapitanOrNewer())
			rect.origin.y += [memoryView rectOfRow:0].size.height;
		unsigned pixelPerRow = (unsigned) ([memoryView rowHeight] + [memoryView intercellSpacing].height);
		range.location = [memoryView rowsInRect:rect].location;
		range.length = rect.size.height / pixelPerRow;
	}
	return range;
}


- (IBAction) selectMemoryInspector:(id)sender
{
	NSSize drawerSize;

	// get the new inspector
	NSFormatter <MemoryInspector> *newInspector = [memoryInspectors objectAtIndex:[sender indexOfSelectedItem]];
	if ([currentInspector isEqual:newInspector])
		return;
	
	// stop editing in the old inspector
	[self cancelEditingInInspector];
	
	NSTableColumn *addrColumn = [memoryView tableColumnWithIdentifier:ADDR_COLUMN_ID];
	NSTableColumn *octalColumn = [memoryView tableColumnWithIdentifier:OCTAL_COLUMN_ID];
	NSTableColumn *contentColumn = [memoryView tableColumnWithIdentifier:CONTENT_COLUMN_ID];
	
	// set octal column width
	drawerSize.width = [addrColumn width];
	float width = [newInspector wordsPerRow] * 35;
	drawerSize.width += width;
	[octalColumn setMinWidth:width];
	[octalColumn setMaxWidth:width];
	[octalColumn setWidth:width];
	
	// set content column width
	width = [newInspector contentWidthInCharacters] * 7 + 4;
	drawerSize.width += width;
	[contentColumn setMinWidth:width];
	[contentColumn setMaxWidth:width];
	[contentColumn setWidth:width];
	
	// resize drawer
	drawerSize.width += 42;
	drawerSize.height = 0;
	[memoryInspectorDrawer setMaxContentSize:drawerSize];
	[memoryInspectorDrawer setMinContentSize:drawerSize];
	[memoryInspectorDrawer setContentSize:drawerSize];
	
	// scroll to a reasonable location
	NSInteger newTopRow = 0;
	NSInteger newSelectedRow = -1;
	if (currentInspector) {
		NSRange visibleRange = [self visibleRange];
		NSInteger selectedRow = [memoryView selectedRow];
		if (NSLocationInRange(selectedRow, visibleRange)) {
			newTopRow = selectedRow * [currentInspector wordsPerRow] /
				[newInspector wordsPerRow] - (selectedRow - visibleRange.location);
			newSelectedRow = newTopRow + (selectedRow - visibleRange.location);
		} else
			newTopRow = visibleRange.location * [currentInspector wordsPerRow] /
				[newInspector wordsPerRow];
		NSInteger lastAddress = (newTopRow + visibleRange.length) * [newInspector wordsPerRow];
		if (lastAddress >= PDP8_MEMSIZE)	// don't show white space at the end of the table view
			newTopRow -= (lastAddress - PDP8_MEMSIZE) / [newInspector wordsPerRow] + 1;
	}
	
	// switch to the new inspector, set the formatter and reload data
	alignment = 0;
	currentInspector = newInspector;
	[[octalColumn dataCell] setObjectValue:nil];	// remove old value with wrong number of words
	[[[octalColumn dataCell] formatter] setNumberOfWords:[currentInspector wordsPerRow]];	
	[[contentColumn dataCell] setObjectValue:nil];	// remove old value with wrong number of words
	[[contentColumn dataCell] setFormatter:currentInspector];
	[memoryView reloadData];

	// set selected row
	[memoryView scrollRowToTop:newTopRow];
	if (newSelectedRow >= 0)
		[memoryView selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow]
			byExtendingSelection:NO];
	else
		[memoryView deselectAll:self];

	// enable or disable corner view for memory alignment
	if ([currentInspector needsMemoryAlignment]) {
		[cornerView setImageNamed:@"alignMemoryArrow" toolTip:
			NSLocalizedString(@"Click or option-click to align multiword formats", @"")];
		[cornerView setClickable:YES];
	} else {
		[cornerView setImageNamed:nil toolTip:nil];
		[cornerView setClickable:NO];
	}
}


- (IBAction) alignMemory:(id)sender
{
	if ([currentInspector needsMemoryAlignment]) {
		[self cancelEditingInInspector];
		int wordsPerRow = [currentInspector wordsPerRow];
		alignment = (alignment + wordsPerRow +
                     (([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagOption) ? -1 : 1)) % wordsPerRow;
		[memoryView reloadData];
	}
}


- (void) notifyMemoryChanged:(NSNotification *)notification
{
	// NSLog (@"MemoryInspectorController notifyMemoryChanged");
	[memoryView reloadData];
}


- (BOOL) tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)column row:(int)row
{
	return [currentInspector wordsPerRow] * (row + 1) + alignment <= [pdp8 memorySize]
		&& ([[column identifier] intValue] != CONTENT_COLUMN || [currentInspector allowsEditing]);
}


- (int) numberOfRowsInTableView:(NSTableView *)tableView
{
	int wordsPerRow = [currentInspector wordsPerRow];
	return wordsPerRow ? (PDP8_MEMSIZE + wordsPerRow - alignment - 1) / wordsPerRow : 0;
}


- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	int i;
	NSMutableArray *value;
	
	int wordsPerRow = [currentInspector wordsPerRow];
	switch ([[column identifier] intValue]) {
	case ADDR_COLUMN :
		return [NSString stringWithFormat:@"%5.5o", wordsPerRow * row + alignment];
	case OCTAL_COLUMN :
		value = [NSMutableArray arrayWithCapacity:wordsPerRow];
		for (i = 0; i < wordsPerRow && wordsPerRow * row + alignment + i < PDP8_MEMSIZE; i++)
			[value addObject:[NSNumber numberWithInt:
				[pdp8 memoryAt:wordsPerRow * row + alignment + i]]];
		return value;
	case CONTENT_COLUMN :
		if (wordsPerRow * (row + 1) /* + alignment */ > [pdp8 memorySize])
			return NSLocalizedString(@"n/a", @"");
		value = [NSMutableArray arrayWithCapacity:wordsPerRow];
		for (i = 0; i < wordsPerRow; i++)
			[value addObject:[NSNumber numberWithInt:
				(wordsPerRow * row + alignment + i < PDP8_MEMSIZE) ?
					[pdp8 memoryAt:wordsPerRow * row + alignment + i] : 0]];
		return value;
	}
	return nil;
}


- (NSString *) tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell
	rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)column row:(int)row
	mouseLocation:(NSPoint)mouseLocation
{
	switch ([[column identifier] intValue]) {
	case ADDR_COLUMN :
		return NSLocalizedString(@"This column displays the memory adresses.", @"");
	case OCTAL_COLUMN :
		return NSLocalizedString(@"This column displays the octal memory content.", @"");
	case CONTENT_COLUMN :
		return [currentInspector toolTipForContentColumn];
	}
	return nil;
}


- (void) tableView:(NSTableView *)tableView setObjectValue:(NSArray *)values
	forTableColumn:(NSTableColumn *)column row:(int)row
{
	/* value == nil when the user tabs (without editing) over cells with
	   output strings that are not valid input strings, e. g. "(IEEE overflow)".
	   In this case, the formatter is called with error == nil, returns the
	   value nil for the invalid input string, but Cocoa does not call
	   control:didFailToFormatString:errorDescription: */
	if (values)
		[pdp8 setMemoryAtAddress:row * [currentInspector wordsPerRow] + alignment
			toValues:values withMask:[[column identifier] intValue] == CONTENT_COLUMN];
}


- (BOOL) control:(NSControl *)control didFailToFormatString:(NSString *)string
	errorDescription:(NSString *)error
{
	NSRange range;
	range.location = 0;
	range.length = -1;
	[[control currentEditor] setSelectedRange:range];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:error];
	[alert beginSheetModalForWindow:[memoryInspectorDrawer parentWindow] completionHandler:^(NSModalResponse returnCode) { }];
	[alert release];
	return NO;
}


- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(cancelOperation:)) {
		// ESC aborts editing of the cell
		[control abortEditing];
		return YES;
	}
	return NO;
}


#pragma mark Delegate and Notification


- (void) drawerWillClose:(NSNotification *)notification
{
	[self cancelEditingInInspector];
	lastTopRow = (unsigned)([self visibleRange].location);
}


- (void) scrollDrawerToLastTopRow
{
	[memoryView scrollRowToTop:lastTopRow];
}


- (void) drawerDidOpen:(NSNotification *)notification
{
	// When the PDP-8 runs, the CPU window shrinks to the title bar, so the memory view scrolls to row 0
	// We can't scroll in drawerWillOpen:; even when this method runs, often the CPU window is still shrunk,
	// so a direct [memoryView scrollRowToTop:lastTopRow] has no effect, and the memory view stays at location 0.
	// So we delay the scrolling via performSelector:, accepting the side effect that the scrolling is visible.
	[self performSelector:@selector(scrollDrawerToLastTopRow) withObject:nil afterDelay:0];
}


- (void) notifyApplicationWillTerminate:(NSNotification *)notification
{
	// NSLog (@"MemoryInspectorController notifyApplicationWillTerminate");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[currentInspector className] forKey:CURRENT_INSPECTOR_CLASS_PREFS_KEY];
	[defaults setObject:[NSNumber numberWithInt:(int)([self visibleRange].location)] forKey:TOP_ROW_PREFS_KEY];
	[defaults setObject:[NSNumber numberWithInt:alignment] forKey:ALIGNMENT_PREFS_KEY];
	NSInteger s = [memoryInspectorDrawer state];
	[defaults setBool:s == NSDrawerOpenState || s == NSDrawerOpeningState
		forKey:INSPECTOR_OPEN_PREFS_KEY];
}


- (void) notifyApplicationDidFinishLaunching:(NSNotification *)notification
/* Look for memory inspector classes at "did finish launching", after plugins have been loaded at
   "will finish launching", so we find inspector classes of plugins, too. */
{
	unsigned i;
	
	memoryInspectors = [[self allMemoryInspectors] retain];
	[popupButton removeAllItems];
	for (i = 0; i < [memoryInspectors count]; i++) 
		[popupButton addItemWithTitle:[[memoryInspectors objectAtIndex:i] menuTitle]];
	NSFont *font = [NSFont userFixedPitchFontOfSize:11];
	[[[[memoryView tableColumns] objectAtIndex:ADDR_COLUMN] dataCell] setFont:font];
	[[[[memoryView tableColumns] objectAtIndex:OCTAL_COLUMN] dataCell] setFont:font];
	[[[[memoryView tableColumns] objectAtIndex:CONTENT_COLUMN] dataCell] setFont:font];
	[[[[memoryView tableColumns] objectAtIndex:OCTAL_COLUMN] dataCell]
		setFormatter:[OctalFormatter formatterWithBitMask:07777 wildcardAllowed:NO]];
	// restore preferences
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *currentInspectorClass = [defaults stringForKey:CURRENT_INSPECTOR_CLASS_PREFS_KEY];
	alignment = 0;
	lastTopRow = 0;
	for (i = 0; i < [memoryInspectors count]; i++) {
		if ([[[memoryInspectors objectAtIndex:i] className] isEqualToString:currentInspectorClass]) {
			[popupButton selectItemAtIndex:i];
			alignment = (int)([defaults integerForKey:ALIGNMENT_PREFS_KEY]);
			lastTopRow = (int)([defaults integerForKey:TOP_ROW_PREFS_KEY]);
			break;
		}
	}
	[self selectMemoryInspector:popupButton];
	[memoryView scrollRowToTop:lastTopRow];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:INSPECTOR_OPEN_PREFS_KEY]
		&& [[memoryInspectorDrawer parentWindow] isVisible])
		[memoryInspectorDrawer open];
}


- (void) awakeFromNib
{
	adjustTableHeaderForElCapitan (memoryView);
	// set notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationDidFinishLaunching:)
		name:NSApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMemoryChanged:)
		name:MEMORY_CHANGED_NOTIFICATION object:nil]; 
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationWillTerminate:)
		name:NSApplicationWillTerminateNotification object:nil]; 
}


@end
