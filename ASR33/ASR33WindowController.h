/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	ASR33WindowController.h - ASR 33 Teletype Window Controller
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


@class ASR33, PaperTapeController, ASR33TextView, RegisterTextField, KeepInMenuWindow;


@interface ASR33WindowController : NSObject
#ifdef __MAC_10_6
	<NSWindowDelegate>	// with the 10.6 SDKs, it is a protocol, before it was an interface
#endif
{
@private
	IBOutlet ASR33			*asr33;
	IBOutlet KeepInMenuWindow	*window;
	IBOutlet NSSegmentedControl	*localOnline;
	IBOutlet NSButton		*flushTypeaheadBuffer;
	IBOutlet RegisterTextField	*kbb;
	IBOutlet RegisterTextField	*tto;
}

- (IBAction) localOnlineClicked:(id)sender;
- (void) setWindowTitle:(NSString *)title;

@end
