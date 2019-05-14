/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	ASR33WindowController.m - ASR 33 Teletype Window Controller
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

#import "PluginFramework/PluginAPI.h"
#import "PluginFramework/KeepInMenuWindow.h"
#import "PluginFramework/Utilities.h"
#import "PluginFramework/InputConsumerProtocol.h"
#import "PluginFramework/RegisterTextField.h"

#import "ASR33WindowController.h"
#import "ASR33.h"


@implementation ASR33WindowController


#pragma mark Notifications


- (void) notifyPluginsLoaded:(NSNotification *)notification
{
	[window orderBackFromDefaults:self];
}


- (void) setupNotifications
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
		selector:@selector(notifyOnlineChanged:) name:TTY_ONLINE_CHANGED_NOTIFICATION object:nil];
	[defaultCenter addObserver:self selector:@selector(notifyPluginsLoaded:)
		name:PLUGINS_LOADED_NOTIFICATION object:nil];
}


#pragma mark Controls


- (IBAction) localOnlineClicked:(id)sender
{
	[asr33 setOnline:(BOOL) [sender selectedSegment]];
}


- (void) notifyOnlineChanged:(NSNotification *)notification
{
	[localOnline setSelectedSegment:[asr33 getOnline]];
}


#pragma mark Initialization


- (void) setWindowTitle:(NSString *)title
{
	BOOL isAuxTTY = ! [[window title] isEqualToString:title];
	NSRect oldFrame = [window frame];
	[window setTitle:title];
	[window setFrameAutosaveName:title];
	/* this is a hack to move the AuxTTY window away from the exact position of the ConTTY when the
	   simulator starts for the first time without existing preferences file */
	if (isAuxTTY && NSEqualRects(oldFrame, [window frame]))
		[window setFrameOrigin:NSMakePoint(oldFrame.origin.x + 20, oldFrame.origin.y - 20)];
}


- (void) setupRegisters
{
	[kbb setupRegisterFor:asr33 getRegisterValue:@selector(getKBB) setRegisterValue:@selector(setKBB:)
		changedNotificationName:KBB_CHANGED_NOTIFICATION mask:0377 base:8];
	[tto setupRegisterFor:asr33 getRegisterValue:@selector(getTTO) setRegisterValue:@selector(setTTO:)
		changedNotificationName:TTO_CHANGED_NOTIFICATION mask:0377 base:8];
}


- (void) awakeFromNib
{
	if (runningOnTiger())
		[flushTypeaheadBuffer setFrame:NSOffsetRect([flushTypeaheadBuffer frame], -2, 0)];
	if (runningOnMojaveOrNewer()) {
		// With Mojave, the right border is not drawn (the other two segmented controls are ok, but their
		// cells have an even number of pixels, this control has segments with an odd number of pixels);
		// for other macOS versions, this seems to cause no visable effect.
		NSRect rect = [localOnline frame];
		rect.size.width += 2;
		[localOnline setFrame:rect];
	}
	[self setupNotifications];
	[self setupRegisters];
}


@end
