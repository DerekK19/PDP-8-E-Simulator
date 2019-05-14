/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	MainController.m - Main Application Controller Class
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
#import <PreferencePanes/PreferencePanes.h>

#import "MainController.h"
#import "CPUWindowController.h"
#import "PDP8.h"
#import "Utilities.h"
#import "BreakpointArray.h"
#import "BreakpointController.h"
#import "GeneralPreferences.h"
#import "CPUPreferences.h"
#import "PluginManager.h"
#import "KeepInMenuWindow.h"
#import "NSWindow+VisibilityDefaults.h"


@implementation MainController


- (void) notifyStopPDP8:(NSNotification *)notification
{
	if (breakpointPanelVisibleBeforeGo) {
		[breakpointPanel orderBack:self];
		breakpointPanelVisibleBeforeGo = NO;
	}
	if (bootstrapPanelVisibleBeforeGo) {
		[bootstrapPanel orderBack:self];
		bootstrapPanelVisibleBeforeGo = NO;
	}
	if (memoryInspectorPanelVisibleBeforeGo) {
		[memoryInspectorPanel orderBack:self];
		memoryInspectorPanelVisibleBeforeGo = NO;
	}
}


- (void) notifyPreferencesChanged:(NSNotification *)notification
{
	// NSLog (@"MainController notifyPreferencesChanged");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[pdp8 mountEAE:[defaults boolForKey:CPU_PREFS_EAE_KEY]];
	/* The preferences may be inconsistent here because NSUserDefaultsController sends the
	   notification before the km8eClick: method of CPUPreferences is called. */ 
	BOOL hasKM8E = [defaults boolForKey:CPU_PREFS_KM8E_KEY];
	unsigned short memsize = (unsigned short) [defaults integerForKey:CPU_PREFS_MEMORYSIZE_KEY];
	memsize = hasKM8E ? max(memsize, 2 * PDP8_FIELDSIZE) : PDP8_FIELDSIZE;
	BOOL hasTimesharing = hasKM8E ? [defaults boolForKey:CPU_PREFS_TIMESHARING_KEY] : NO;
	[pdp8 mountKM8E:hasKM8E memorySize:memsize timesharingEnabled:hasTimesharing];
	[pdp8 setTraceSpeed:[defaults floatForKey:GENERAL_PREFS_TRACE_SPEED_KEY]];
	[pdp8 setGoSpeed:(int) [defaults integerForKey:GENERAL_PREFS_GO_SPEED_KEY]];
}


- (void) cancelEditing
{
	/* Cancel editing (in memory table views). Otherwise the [tableview reload]
	   caused by [pdp8 reset] ends editing normally, and this causes values from
	   the active input field to be written back to the PDP-8 memory. Send the
	   cancelOperation: only to NSTextView subclasses to avoid a beep caused by
	   other responders. */
	NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
	if ([[firstResponder class] isSubclassOfClass:[NSTextView class]]) {
		[firstResponder doCommandBySelector:@selector(cancelOperation:)];
#if __LP64__
		// let the run loop run for a microsecond, otherwise the applications hangs for seconds
		// when the user clicks "Go" while a memory cell in the CPU window is activated for editing
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.000001]];
#endif
	}
}


- (IBAction) reset:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];

	[alert setMessageText:NSLocalizedString(@"Do you really want to reset the PDP-8/E?", @"")];
	[alert setInformativeText:NSLocalizedString(
		@"All registers and the memory content will be set to zero. "
		@"The preferences and mounted tapes, disks etc. will be preserved. "
		@"All breakpoints and break opcodes will be disabled.", @"")];
	[[alert addButtonWithTitle:NSLocalizedString(@"Yes", @"")] setKeyEquivalent:@"\r"];
	[[alert addButtonWithTitle:NSLocalizedString(@"No", @"")] setKeyEquivalent:@"\e"];
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		[self cancelEditing];
		[pdp8 reset];
		[breakpoints setAllValues:0];
		[breakopcodes setAllValues:0];
		[pluginManager resetAllDevices];
	}
	[alert release];
}


- (IBAction) step:(id)sender
{
	[self cancelEditing];
	[pdp8 step];
}


- (IBAction) trace:(id)sender
{
	[self cancelEditing];
	[pdp8 trace:NO_STOP_ADDRESS];
}


- (IBAction) go:(id)sender
{
	breakpointPanelVisibleBeforeGo = [breakpointPanel isVisible];
	bootstrapPanelVisibleBeforeGo = [bootstrapPanel isVisible];
	memoryInspectorPanelVisibleBeforeGo = [memoryInspectorPanel isVisible];
	[breakpointPanel orderOut:self];
	[bootstrapPanel orderOut:self];
	[memoryInspectorPanel orderOut:self];
	[self cancelEditing];
	[pdp8 go:NO_STOP_ADDRESS];
}


- (IBAction) stop:(id)sender
{
	[pdp8 stop];
}


- (IBAction) showPreferencesPanel:(id)sender
{
	[preferencesPanel makeKeyAndOrderFront:self];
}


-(void) showHidePanel:(NSPanel *)panel
{
	if ([panel isVisible])
		[panel orderOut:self];
	else
		[panel makeKeyAndOrderFront:self];
	// Save the visibility state of the three panels whenever the user shows or hides a panel, so it is
	// correctly shown or hidden on the next application state even when the user quits the simulator while
	// the PDP-8 is running (and the panels are hidden).
	[panel saveVisibilityInDefaults:NO];
}


- (IBAction) showHideBreakpointPanel:(id)sender
{
	[self showHidePanel:breakpointPanel];
}


- (IBAction) showHideBootstrapPanel:(id)sender
{
	[self showHidePanel:bootstrapPanel];
}


- (IBAction) showHideMemoryInspectorPanel:(id)sender
{
	[self showHidePanel:memoryInspectorPanel];
}


- (void) windowWillClose:(NSNotification *)notification
{
	// Called for the delegate of one of the three panels when the user clicks the red close button of the panel
	// or when the application terminates. Save the inverted state, because just now the panel is still visible.
	if (! applicationIsTerminating)
		[[notification object] saveVisibilityInDefaults:YES];
}


- (IBAction) loadPaperTape:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setTitle:NSLocalizedString(@"Load a Paper Tape", @"")];
	[panel setPrompt:NSLocalizedString(@"Load", @"")];
	[loadPaperTapeFieldView retain];
	// [loadPaperTapeFieldStepper setIntValue:[pdp8 getIF]];
	int lastField = ([pdp8 memorySize] >> 12) - 1;
	[loadPaperTapeFieldStepper setMaxValue:lastField];
	[loadPaperTapeFieldStepper setEnabled:lastField != 0];
	[[loadPaperTapeFieldStepper target] performSelector:[loadPaperTapeFieldStepper action]
		withObject:loadPaperTapeFieldStepper];
	[panel setAccessoryView:loadPaperTapeFieldView];
	if ([panel respondsToSelector:@selector(setAccessoryViewDisclosed:)]) {
		// this is a 10.11 method, otherwise the field selector is hidden by default on El Capitan or newer
		[panel performSelector:@selector(setAccessoryViewDisclosed:) withObject:(NSObject *) YES];
	}
	if ([panel runModalForDirectory:
		[[NSUserDefaults standardUserDefaults] stringForKey:LAST_FILE_PANEL_DIR_KEY]
			file:nil types:[NSArray arrayWithObjects:
			NSFileTypeForHFSTypeCode(0x504e4348l /* 'PNCH' */),
			@"BIN", @"bin", @"BN", @"bn", @"RIM", @"rim", @"PT", @"pt", nil]] == NSOKButton) {
		[self cancelEditing];
		NSString *error = [pdp8 loadPaperTape:[panel filename]
			toField:(ushort) [loadPaperTapeFieldStepper intValue]];
		if (error) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setMessageText:error];
			[alert setInformativeText:[panel filename]];
			[alert runModal];
			[alert release];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:[panel directory] forKey:LAST_FILE_PANEL_DIR_KEY];
}


- (IBAction) clearAllFlags:(id)sender
{
	[self cancelEditing];
	[pdp8 clearAllFlags];
}


- (IBAction) loadExtendedAddress:(id)sender
{
	[self cancelEditing];
	[pdp8 loadExtendedAddress];
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	if (action == @selector(stop:))
		return [pdp8 isRunning];
	if (action == @selector(step:) || action == @selector(trace:) || action == @selector(go:))
		return ! [pdp8 isHalted] && [pdp8 isStopped];
	if (action == @selector(reset:) || action == @selector(loadPaperTape:) ||
		action == @selector(clearAllFlags:) || action == @selector(loadExtendedAddress:))
		return [pdp8 isStopped];
	if (action == @selector(showHideBreakpointPanel:)) {
		if ([menuItem respondsToSelector:@selector(setState:)])
			[menuItem setState:[breakpointPanel isVisible]];
		return ! [pdp8 isGoing];
	}
	if (action == @selector(showHideBootstrapPanel:)) {
		if ([menuItem respondsToSelector:@selector(setState:)])
			[menuItem setState:[bootstrapPanel isVisible]];
		return ! [pdp8 isGoing];
	}
	if (action == @selector(showHideMemoryInspectorPanel:)) {
		if ([menuItem respondsToSelector:@selector(setState:)])
			[menuItem setState:[memoryInspectorPanel isVisible]];
		return ! [pdp8 isGoing];
	}
	if (action == @selector(performZoomAll:)) {	// don't know how to archieve this automatically
		NSWindow *window;
		NSEnumerator *enumerator = [[NSApp windows] objectEnumerator];
		while ((window = [enumerator nextObject])) {
			if ([window level] == NSNormalWindowLevel &&
				[window isZoomable] && [window isVisible])
				return TRUE;
		}
		return FALSE;
	}
	return TRUE;
}


- (BOOL) validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	return [self validateMenuItem:(NSMenuItem *)toolbarItem];
}


- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
	applicationIsTerminating = NO;
	if (! runningOnTigerOrNewer()) {
		NSRunAlertPanel (
			NSLocalizedString(
				@"This version of the PDP-8/E Simulator needs Mac OS X 10.4 or better", @""),
			NSLocalizedString(@"For older Systems (down to System 2.0.1 on a Mac 512Ke), there "
				"is still the old version 1.5 of the PDP-8/E Simulator available.", @""),
			NSLocalizedString(@"Quit", @""), nil, nil);
		exit (0);
	}
	LOG_ASSERTING ();
}


- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyStopPDP8:) name:PDP8_STOP_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyPreferencesChanged:) name:NSUserDefaultsDidChangeNotification
		object:nil];
	[self notifyPreferencesChanged:nil];
	[breakpoints loadFromPrefs:@"Breakpoints"];
	[breakopcodes loadFromPrefs:@"BreakOpcodes"];
	if ([breakpointPanel getVisibilityFromDefaults])
		[breakpointPanel orderFront:self];
	if ([bootstrapPanel getVisibilityFromDefaults])
		[bootstrapPanel orderFront:self];
	if ([memoryInspectorPanel getVisibilityFromDefaults])
		[memoryInspectorPanel orderFront:self];
	[[cpuWindow toolbar] validateVisibleItems];	// revalidate because of the HALT/SINGSTEP console key
#if __LP64__
	/* with PC=00214 and 64-bit mode, without this, the CPU window shows locations 00167-00213: PC invisible */
	[pdp8 setProgramCounter:[pdp8 getProgramCounter]];
#endif
	[cpuWindow orderFrontFromDefaults:self];
	[cpuWindow makeKeyWindow];
}


- (void) applicationWillTerminate:(NSNotification *)notification 
{
	applicationIsTerminating = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification
		object:nil];
}


- (IBAction) performZoomAll:(id)sender		// don't know how to archieve this automatically
{
	NSWindow *window;
	NSEnumerator *enumerator = [[NSApp windows] objectEnumerator];
	while ((window = [enumerator nextObject])) {
		if ([window level] == NSNormalWindowLevel && [window isZoomable] && [window isVisible])
			[window performZoom:sender];
	}
}


@end
