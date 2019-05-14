/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	CPUWindowController.h - Controller for the CPU window
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


@class RegisterTextField, EnableDisableTextField, PDP8;


@interface CPUWindowController : NSObject
#ifdef __MAC_10_6
	<NSWindowDelegate, NSToolbarDelegate>	// with the 10.6 SDKs, it is a protocol, before it was an interface
#endif
{
@private
	IBOutlet NSWindow		*window;
	IBOutlet RegisterTextField	*sr;
	IBOutlet RegisterTextField	*l;
	IBOutlet RegisterTextField	*ac;
	IBOutlet RegisterTextField	*pc;
	IBOutlet EnableDisableTextField	*scLabel;
	IBOutlet RegisterTextField	*sc;
	IBOutlet EnableDisableTextField	*gtfLabel;
	IBOutlet RegisterTextField	*gtf;
	IBOutlet RegisterTextField	*mq;
	IBOutlet EnableDisableTextField	*modeLabel;
	IBOutlet NSButton		*a;
	IBOutlet NSButton		*b;
	IBOutlet EnableDisableTextField	*dfLabel;
	IBOutlet RegisterTextField	*df;
	IBOutlet EnableDisableTextField	*ifLabel;
	IBOutlet RegisterTextField	*_if;
	IBOutlet EnableDisableTextField	*ibLabel;
	IBOutlet RegisterTextField	*ib;
	IBOutlet EnableDisableTextField	*ufLabel;
	IBOutlet RegisterTextField	*uf;
	IBOutlet EnableDisableTextField	*ubLabel;
	IBOutlet RegisterTextField	*ub;
	IBOutlet EnableDisableTextField	*sfLabel;
	IBOutlet RegisterTextField	*sf;
	IBOutlet NSButton		*enable;
	IBOutlet NSButton		*delay;
	IBOutlet NSButton		*inhibit;
	IBOutlet PDP8			*pdp8;
	float				normalContentHeight;
}

- (IBAction) eaeModeButtonClick:(id)sender;
- (IBAction) enableCheckboxClicked:(id)sender;
- (IBAction) delayCheckboxClicked:(id)sender;
- (IBAction) inhibitCheckboxClicked:(id)sender;

@end
