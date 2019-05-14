/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
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

#import "Utilities.h"	// for NSIntger, NSUInteger only
#import "MemoryInspectorController.h"
#import "MemoryInspectorProtocol.h"
#import "NonWrappingTableView.h"
#import "NSTableView+Scrolling.h"
#import "NSFont+Monaco.h"
#import "TableCornerView.h"
#import "OctalFormatter.h"
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

#define ALIGN_ARROW_IMAGE			@"alignMemoryArrow"
#define ALIGN_ARROW_IMAGE_DARK			@"alignMemoryArrowDark"


@implementation NSFormatter (OrderInMemoryInspectorMenu)


- (NSComparisonResult) compareOrderInMemoryInspectorMenu:(id <MemoryInspector>)inspector
{
	return [[(id <MemoryInspector>) self orderInMemoryInspectorMenu]
		compare:[inspector orderInMemoryInspectorMenu]];
}


@end


#ifndef __MAC_10_5		// forward declaration for the good old Xcode 3.2.6 compiler

@interface MemoryInspectorController (private)

- (void) notifyUpdateAlignMemoryIndicator:(NSNotification *)notification;

@end

#endif


@implementation MemoryInspectorController


- (void) cancelEditingInInspector
{
	NSResponder *first, *next;
	
	for (first = next = [[NSApp keyWindow] firstResponder]; next; next = [next nextResponder]) {
		if (next == [memoryInspectorPanel contentView] &&
			[[first class] isSubclassOfClass:[NSTextView class]]) {
			[first doCommandBySelector:@selector(cancelOperation:)];
			break;
		}
	}
}


#ifndef __MAC_10_5

#define class_getSuperclass(currentClass)	((currentClass)->super_class)

#endif


- (NSArray *) allMemoryInspectors
{
	int i;
	
	int numClasses = objc_getClassList(NULL, 0);
	Class *allClasses = malloc(sizeof(Class) * numClasses);
	numClasses = objc_getClassList(allClasses, numClasses);
	NSMutableArray *inspectors = [NSMutableArray array];
	for (i = 0; i < numClasses; i++) {
		Class currentClass = allClasses[i];
		while (currentClass) {
			if (class_getSuperclass(currentClass) == [NSFormatter class] &&
				[currentClass conformsToProtocol:@protocol(MemoryInspector)]) {
				[inspectors addObject:[[[allClasses[i] alloc] init] autorelease]];
				break;
			}
			currentClass = class_getSuperclass(currentClass);
		}
	}
	free (allClasses);
	[inspectors sortUsingSelector:@selector(compareOrderInMemoryInspectorMenu:)];
	return inspectors;
}


- (NSRange) visibleRange
{
	// see also [CPUMemoryViewController updateVisibleMemoryRange] and [NSTableView(Scrolling) scrollRowToTop:]
	NSRect rect = [memoryView visibleRect];
	if (runningOnElCapitanOrNewer() && [(NSClipView *) [memoryView superview] visibleRect].origin.y >= 0)
		rect.origin.y += [memoryView rectOfRow:0].size.height;
	unsigned pixelPerRow = (unsigned) ([memoryView rowHeight] + [memoryView intercellSpacing].height);
	return NSMakeRange([memoryView rowsInRect:rect].location, (NSUInteger) rect.size.height / pixelPerRow);
}


- (IBAction) selectMemoryInspector:(id)sender
{
	NSSize size = [[memoryInspectorPanel contentView] frame].size;

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
	size.width = [addrColumn width];
	float width = [newInspector wordsPerRow] * 35;
	size.width += width;
	[octalColumn setMinWidth:width];
	[octalColumn setMaxWidth:width];
	[octalColumn setWidth:width];
	
	// set content column width
	width = [newInspector contentWidthInCharacters] * 7 + 4;
	size.width += width;
	if (! runningOnLionOrNewer())	// otherwise, there are two separators next to the table corner view
		width += 2;
	[contentColumn setMinWidth:width];
	[contentColumn setMaxWidth:width];
	[contentColumn setWidth:width];
	
	// resize the panel
	size.width += 22;
	[memoryInspectorPanel setContentMinSize:NSMakeSize(size.width, [memoryInspectorPanel contentMinSize].height)];
	[memoryInspectorPanel setContentMaxSize:NSMakeSize(size.width, [memoryInspectorPanel contentMaxSize].height)];
	[memoryInspectorPanel setContentSize:size];
	
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
	[memoryView scrollRowToTop:(int) newTopRow];
	if (newSelectedRow >= 0)
		[memoryView selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow]
			byExtendingSelection:NO];
	else
		[memoryView deselectAll:self];

	// enable or disable corner view for memory alignment
	[self notifyUpdateAlignMemoryIndicator:nil];
}


- (IBAction) alignMemory:(id)sender
{
	if ([currentInspector needsMemoryAlignment]) {
		[self cancelEditingInInspector];
		int wordsPerRow = [currentInspector wordsPerRow];
		alignment = (alignment + wordsPerRow +
			(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ? -1 : 1)) % wordsPerRow;
		[memoryView reloadData];
	}
}


- (void) notifyMemoryChanged:(NSNotification *)notification
{
	// NSLog (@"MemoryInspectorController notifyMemoryChanged");
	[memoryView reloadData];
}


- (BOOL) tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return [currentInspector wordsPerRow] * (row + 1) + alignment <= [pdp8 memorySize]
		&& ([[column identifier] intValue] != CONTENT_COLUMN || [currentInspector allowsEditing]);
}


- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	int wordsPerRow = [currentInspector wordsPerRow];
	return wordsPerRow ? (PDP8_MEMSIZE + wordsPerRow - alignment - 1) / wordsPerRow : 0;
}


- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	int i;
	NSMutableArray *value;
	
	int wordsPerRow = [currentInspector wordsPerRow];
	switch ([[column identifier] intValue]) {
	case ADDR_COLUMN :
		return [NSString stringWithFormat:@"%5.5o", (int) (wordsPerRow * row + alignment)];
	case OCTAL_COLUMN :
		value = [NSMutableArray arrayWithCapacity:wordsPerRow];
		for (i = 0; i < wordsPerRow && wordsPerRow * row + alignment + i < PDP8_MEMSIZE; i++)
			[value addObject:[NSNumber numberWithInt:
				[pdp8 memoryAt:wordsPerRow * (int) row + alignment + i]]];
		return value;
	case CONTENT_COLUMN :
		if (wordsPerRow * (row + 1) /* + alignment */ > [pdp8 memorySize])
			return NSLocalizedString(@"n/a", @"");
		value = [NSMutableArray arrayWithCapacity:wordsPerRow];
		for (i = 0; i < wordsPerRow; i++)
			[value addObject:[NSNumber numberWithInt:
				(wordsPerRow * row + alignment + i < PDP8_MEMSIZE) ?
					[pdp8 memoryAt:(int) (wordsPerRow * row + alignment + i)] : 0]];
		return value;
	}
	return nil;
}


- (NSString *) tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell
	rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)column row:(NSInteger)row
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
	return @"";
}


- (void) tableView:(NSTableView *)tableView setObjectValue:(NSArray *)values
	forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	/* values == nil when the user tabs (without editing) over cells with
	   output strings that are not valid input strings, e. g. "(IEEE overflow)".
	   In this case, the formatter is called with error == nil, returns the
	   value nil for the invalid input string, but Cocoa does not call
	   control:didFailToFormatString:errorDescription: */
	if (values)
		[pdp8 setMemoryAtAddress:(int) (row * [currentInspector wordsPerRow] + alignment)
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
	[alert beginSheetModalForWindow:[control window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
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


- (void) notifyApplicationWillTerminate:(NSNotification *)notification
{
	// NSLog (@"MemoryInspectorController notifyApplicationWillTerminate");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[currentInspector className] forKey:CURRENT_INSPECTOR_CLASS_PREFS_KEY];
	[defaults setObject:[NSNumber numberWithInt:(int) [self visibleRange].location] forKey:TOP_ROW_PREFS_KEY];
	[defaults setObject:[NSNumber numberWithInt:alignment] forKey:ALIGNMENT_PREFS_KEY];
}


- (void) notifyApplicationDidFinishLaunching:(NSNotification *)notification
/* Look for memory inspector classes at "did finish launching", after plug-ins have been loaded at
   "will finish launching", so we find inspector classes of plug-ins, too. */
{
	unsigned i;
	
	memoryInspectors = [[self allMemoryInspectors] retain];
	[popupButton removeAllItems];
	for (i = 0; i < [memoryInspectors count]; i++)
		[popupButton addItemWithTitle:[[memoryInspectors objectAtIndex:i] menuTitle]];
	NSFont *font = [NSFont monaco11];
	[[[[memoryView tableColumns] objectAtIndex:ADDR_COLUMN] dataCell] setFont:font];
	[[[[memoryView tableColumns] objectAtIndex:OCTAL_COLUMN] dataCell] setFont:font];
	[[[[memoryView tableColumns] objectAtIndex:CONTENT_COLUMN] dataCell] setFont:font];
	[[[[memoryView tableColumns] objectAtIndex:OCTAL_COLUMN] dataCell]
		setFormatter:[OctalFormatter formatterWithBitMask:07777 wildcardAllowed:NO]];
	// restore preferences
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *currentInspectorClass = [defaults stringForKey:CURRENT_INSPECTOR_CLASS_PREFS_KEY];
	BOOL inspectorFound = NO;
	for (i = 0; i < [memoryInspectors count]; i++) {
		if ([[[memoryInspectors objectAtIndex:i] className] isEqualToString:currentInspectorClass]) {
			[popupButton selectItemAtIndex:i];
			inspectorFound = YES;
			break;
		}
	}
	[self selectMemoryInspector:popupButton];
	if (inspectorFound) {
		// inspector of a plug-in might not be present after restart of the app
		// when the plug-in is removed, we open the memory inspector with 6-Bit ASCII at location 0
		alignment = (unsigned) [defaults integerForKey:ALIGNMENT_PREFS_KEY];
		unsigned lastTopRow = (unsigned) [defaults integerForKey:TOP_ROW_PREFS_KEY];
		[memoryView scrollRowToTop:lastTopRow];
	}
}


- (void) notifyUpdateAlignMemoryIndicator:(NSNotification *)notification
{
	if ([currentInspector needsMemoryAlignment]) {
		[cornerView setImageNamed:isMojaveDarkModeActive() ? ALIGN_ARROW_IMAGE_DARK : ALIGN_ARROW_IMAGE
			toolTip:NSLocalizedString(@"Click or option-click to align multiword formats", @"")];
		[cornerView setClickable:YES];
	} else {
		[cornerView setImageNamed:nil toolTip:nil];
		[cornerView setClickable:NO];
	}
}


- (void) awakeFromNib
{
	if (runningOnTiger()) {
		// otherwise, the title is not centered vertically; with Tiger it is left aligned, not centered
		[popupButton setBordered:NO];
	}
	adjustTableHeaderForElCapitan (memoryView);
	[cornerView setBounds:NSOffsetRect([cornerView bounds], 1, 0)];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationDidFinishLaunching:)
		name:NSApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMemoryChanged:)
		name:MEMORY_CHANGED_NOTIFICATION object:nil]; 
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationWillTerminate:)
		name:NSApplicationWillTerminateNotification object:nil]; 
#if __LP64__
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyUpdateAlignMemoryIndicator:) name:THEME_CHANGED_NOTIFICATION object:nil];
#endif
}


@end
